import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/settings/data/api/notification_preferences_api.dart';
import 'package:spendyholik/features/settings/data/models/models.dart';
import 'package:spendyholik/features/settings/data/models/notification_preferences_dtos.dart';
import 'package:spendyholik/features/settings/data/repositories/remote_notification_preferences_repository.dart';
import 'package:talker/talker.dart';

import '../../../../helpers/dio_errors.dart';

class MockNotificationPreferencesApi extends Mock
    implements NotificationPreferencesApi {}

class MockApiCache extends Mock implements ApiCache {}

/// Форма `ProfileOut` из схемы API: лишние поля DTO должен пропустить.
NotificationPreferencesDto profile({
  bool budget = true,
  bool goal = true,
  bool recurring = false,
  bool income = true,
}) => NotificationPreferencesDto.fromJson({
  'user_id': 'u1',
  'first_name': 'Анна',
  'email': 'anna@example.com',
  'email_verified': true,
  'base_currency': 'RUB',
  'notify_budget': budget,
  'notify_goal': goal,
  'notify_recurring': recurring,
  'notify_income': income,
  'notify_weekly_report': true,
});

void main() {
  late MockNotificationPreferencesApi api;
  late MockApiCache cache;
  late RemoteNotificationPreferencesRepository repository;

  setUpAll(() => registerFallbackValue(profile()));

  setUp(() {
    api = MockNotificationPreferencesApi();
    cache = MockApiCache();
    when(() => cache.generation).thenReturn(0);
    when(() => cache.read(any())).thenAnswer((_) async => null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    repository = RemoteNotificationPreferencesRepository(
      api,
      CachedReader(
        cache,
        NetworkStatus(),
        Talker(settings: TalkerSettings(useConsoleLogs: false)),
      ),
      cache,
    );
  });

  test('load — notify_* из профиля', () async {
    when(() => api.get()).thenAnswer((_) async => profile(income: false));

    expect(
      await repository.load(),
      const NotificationPreferences(
        budget: true,
        goal: true,
        recurring: false,
        income: false,
      ),
    );
  });

  test('load без сети — из своего кэша, не из кэша профиля', () async {
    when(() => api.get()).thenThrow(networkError());
    when(() => cache.read('profile/notifications'))
        .thenAnswer((_) async => jsonEncode(profile(goal: false).toJson()));

    expect((await repository.load()).goal, isFalse);
    verifyNever(() => cache.read('profile'));
  });

  test('save — PATCH только notify_*, ответ — в кэш', () async {
    when(() => api.update(any()))
        .thenAnswer((_) async => profile(budget: false));

    final saved = await repository.save(
      const NotificationPreferences(
        budget: false,
        goal: true,
        recurring: false,
        income: true,
      ),
    );

    expect(saved.budget, isFalse);
    final body =
        verify(() => api.update(captureAny())).captured.single
            as NotificationPreferencesDto;
    expect(body.toJson(), {
      'notify_budget': false,
      'notify_goal': true,
      'notify_recurring': false,
      'notify_income': true,
    });
    verify(() => cache.write('profile/notifications', any())).called(1);
  });

  test('save без сети — NetworkFailure, кэш не пишется', () async {
    when(() => api.update(any())).thenThrow(networkError());

    await expectLater(
      repository.save(
        const NotificationPreferences(
          budget: true,
          goal: true,
          recurring: true,
          income: true,
        ),
      ),
      throwsA(isA<NetworkFailure>()),
    );
    verifyNever(() => cache.write(any(), any()));
  });
}
