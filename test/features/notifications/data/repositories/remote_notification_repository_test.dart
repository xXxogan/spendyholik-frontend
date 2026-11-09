import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/notifications/data/api/notifications_api.dart';
import 'package:spendyholik/features/notifications/data/models/models.dart';
import 'package:spendyholik/features/notifications/data/models/notification_dtos.dart';
import 'package:spendyholik/features/notifications/data/repositories/remote_notification_repository.dart';
import 'package:talker/talker.dart';

import '../../../../helpers/dio_errors.dart';

class MockNotificationsApi extends Mock implements NotificationsApi {}

class MockApiCache extends Mock implements ApiCache {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

class MockTalker extends Mock implements Talker {}

/// Форма `NotificationOut` из схемы API.
NotificationOutDto note({
  String id = 'n1',
  String type = 'income_received',
  int? amountMinor = 5000,
  int? percent,
  bool isRead = false,
  String? createdAt = '2026-10-05T10:00:00Z',
}) => NotificationOutDto.fromJson({
  'id': id,
  'type': type,
  'subject': 'Зарплата',
  'amount_minor': amountMinor,
  'percent': percent,
  'title': 'серверный заголовок',
  'body': 'серверный текст',
  'is_read': isRead,
  'created_at': createdAt,
});

void main() {
  late MockNotificationsApi api;
  late MockApiCache cache;
  late MockDataChangeBus bus;
  late MockTalker talker;
  late RemoteNotificationRepository repository;

  setUpAll(() {
    registerFallbackValue(<DataTopic>{});
  });

  setUp(() {
    api = MockNotificationsApi();
    cache = MockApiCache();
    bus = MockDataChangeBus();
    talker = MockTalker();
    when(() => cache.read(any())).thenAnswer((_) async => null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    repository = RemoteNotificationRepository(
      api,
      CachedReader(cache, NetworkStatus(), Talker()),
      bus,
      talker,
    );
  });

  group('маппинг', () {
    test('все известные типы → NotificationKind, поля переносятся', () async {
      when(() => api.list()).thenAnswer(
        (_) async => [
          note(id: '1', type: 'budget_almost_spent', percent: 90),
          note(id: '2', type: 'income_received'),
          note(id: '3', type: 'recurring_tomorrow'),
          note(id: '4', type: 'goal_progress', percent: 50, amountMinor: null),
        ],
      );

      final list = await repository.getNotifications();
      final byId = {for (final n in list) n.id: n};

      expect(byId['1']!.kind, NotificationKind.budgetAlmostSpent);
      expect(byId['1']!.percent, 90);
      expect(byId['2']!.kind, NotificationKind.incomeReceived);
      expect(byId['2']!.amount, 5000);
      expect(byId['2']!.subject, 'Зарплата');
      expect(byId['2']!.isRead, isFalse);
      expect(byId['2']!.createdAt, DateTime.parse('2026-10-05T10:00:00Z'));
      expect(byId['3']!.kind, NotificationKind.recurringTomorrow);
      expect(byId['4']!.kind, NotificationKind.goalProgress);
      expect(byId['4']!.amount, isNull);
    });

    test('неизвестный тип пропущен с warning', () async {
      when(() => api.list()).thenAnswer(
        (_) async => [note(id: 'ok'), note(id: 'bad', type: 'new_thing')],
      );

      final list = await repository.getNotifications();

      expect(list.map((n) => n.id), ['ok']);
      verify(() => talker.warning(any())).called(1);
    });

    test('created_at null → эпоха, в конец списка', () async {
      when(() => api.list()).thenAnswer(
        (_) async => [note(id: 'nodate', createdAt: null), note(id: 'dated')],
      );

      final list = await repository.getNotifications();

      expect(list.map((n) => n.id), ['dated', 'nodate']);
      expect(list.last.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  test('сортировка по created_at убыв.', () async {
    when(() => api.list()).thenAnswer(
      (_) async => [
        note(id: 'old', createdAt: '2026-10-01T10:00:00Z'),
        note(id: 'new', createdAt: '2026-10-09T10:00:00Z'),
        note(id: 'mid', createdAt: '2026-10-05T10:00:00Z'),
      ],
    );

    final list = await repository.getNotifications();

    expect(list.map((n) => n.id), ['new', 'mid', 'old']);
  });

  group('getUnreadCount', () {
    test('число непрочитанных из списка', () async {
      when(() => api.list()).thenAnswer(
        (_) async => [
          note(id: '1'),
          note(id: '2', isRead: true),
          note(id: '3'),
          note(id: '4', type: 'unknown'),
        ],
      );

      expect(await repository.getUnreadCount(), 2);
    });

    test('без сети и кэша → NetworkFailure', () async {
      when(() => api.list()).thenThrow(networkError());

      expect(repository.getUnreadCount(), throwsA(isA<NetworkFailure>()));
    });
  });

  group('markRead', () {
    test('POST и emit темы notifications', () async {
      when(() => api.markRead('n1')).thenAnswer((_) async {});

      await repository.markRead('n1');

      verify(() => api.markRead('n1')).called(1);
      verify(() => bus.emit({DataTopic.notifications})).called(1);
    });

    test('без сети → NetworkFailure, emit не вызван', () async {
      when(() => api.markRead('n1')).thenThrow(networkError());

      await expectLater(
        repository.markRead('n1'),
        throwsA(isA<NetworkFailure>()),
      );
      verifyNever(() => bus.emit(any()));
    });
  });
}
