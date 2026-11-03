import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/notifications/data/models/notification_model.dart';
import 'package:spendyholik/features/notifications/data/repositories/notification_repository.dart';
import 'package:spendyholik/features/notifications/presentation/cubit/notifications_cubit.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

NotificationModel notification(String id, {bool read = false}) =>
    NotificationModel(
      id: id,
      kind: NotificationKind.budgetAlmostSpent,
      createdAt: DateTime(2026, 11, 3, 10),
      isRead: read,
      subject: 'Развлечения',
      percent: 86,
    );

void main() {
  late MockNotificationRepository repository;
  late MockDataChangeBus bus;
  late StreamController<Set<DataTopic>> changes;

  final unread = notification('n1');
  final read = notification('n2', read: true);

  setUp(() {
    repository = MockNotificationRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  NotificationsCubit build() => NotificationsCubit(repository, bus);

  blocTest<NotificationsCubit, NotificationsState>(
    'загрузка: loading → лента',
    setUp: () =>
        when(() => repository.getNotifications())
            .thenAnswer((_) async => [unread, read]),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const NotificationsState.loading(),
      NotificationsState.loaded([unread, read]),
    ],
  );

  blocTest<NotificationsCubit, NotificationsState>(
    'уведомлений нет — empty',
    setUp: () =>
        when(() => repository.getNotifications()).thenAnswer((_) async => []),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const NotificationsState.loading(),
      const NotificationsState.empty(),
    ],
  );

  blocTest<NotificationsCubit, NotificationsState>(
    'ошибка — error',
    setUp: () =>
        when(() => repository.getNotifications())
            .thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const NotificationsState.loading(),
      const NotificationsState.error(NetworkFailure()),
    ],
  );

  blocTest<NotificationsCubit, NotificationsState>(
    'markRead: сразу помечает прочитанным и зовёт репозиторий',
    setUp: () {
      when(() => repository.getNotifications())
          .thenAnswer((_) async => [unread, read]);
      when(() => repository.markRead('n1')).thenAnswer((_) async {});
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.markRead('n1');
    },
    skip: 2,
    expect: () => [
      isA<NotificationsLoaded>()
          .having((s) => s.notifications.first.isRead, 'n1 read', true)
          .having((s) => s.notifications.last.isRead, 'n2 read', true),
    ],
    verify: (_) => verify(() => repository.markRead('n1')).called(1),
  );

  blocTest<NotificationsCubit, NotificationsState>(
    'markRead прочитанного — без обращения к репозиторию',
    setUp: () =>
        when(() => repository.getNotifications())
            .thenAnswer((_) async => [unread, read]),
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.markRead('n2');
    },
    skip: 2,
    expect: () => <NotificationsState>[],
    verify: (_) => verifyNever(() => repository.markRead(any())),
  );

  blocTest<NotificationsCubit, NotificationsState>(
    'ошибка markRead — пометка откатывается',
    setUp: () {
      when(() => repository.getNotifications())
          .thenAnswer((_) async => [unread]);
      when(() => repository.markRead('n1')).thenThrow(const NetworkFailure());
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.markRead('n1');
    },
    skip: 2,
    expect: () => [
      isA<NotificationsLoaded>().having(
        (s) => s.notifications.single.isRead,
        'read',
        true,
      ),
      NotificationsState.loaded([unread]),
    ],
  );
}
