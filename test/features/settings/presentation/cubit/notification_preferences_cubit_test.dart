import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/features/settings/data/models/models.dart';
import 'package:spendyholik/features/settings/data/repositories/repositories.dart';
import 'package:spendyholik/features/settings/presentation/cubit/notification_preferences_cubit.dart';

class MockNotificationPreferencesRepository extends Mock
    implements NotificationPreferencesRepository {}

const allOn = NotificationPreferences(
  budget: true,
  goal: true,
  recurring: true,
  income: true,
);

void main() {
  late MockNotificationPreferencesRepository repository;

  setUpAll(() => registerFallbackValue(allOn));

  setUp(() => repository = MockNotificationPreferencesRepository());

  NotificationPreferencesCubit build() =>
      NotificationPreferencesCubit(repository);

  blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
    'load — с сервера; ошибка — error',
    setUp: () => when(() => repository.load()).thenAnswer((_) async => allOn),
    build: build,
    act: (cubit) async {
      await cubit.load();
      when(() => repository.load()).thenThrow(const NetworkFailure());
      await cubit.load();
    },
    expect: () => [
      const NotificationPreferencesState.loading(),
      const NotificationPreferencesState.loaded(allOn),
      const NotificationPreferencesState.loading(),
      const NotificationPreferencesState.error(NetworkFailure()),
    ],
  );

  blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
    'toggle — сразу новое значение, на сервер весь набор',
    setUp: () => when(() => repository.save(any())).thenAnswer(
      (i) async => i.positionalArguments.single as NotificationPreferences,
    ),
    build: build,
    seed: () => const NotificationPreferencesState.loaded(allOn),
    act: (cubit) => cubit.toggle(.income, false),
    expect: () => [
      NotificationPreferencesState.loaded(allOn.copyWith(income: false)),
    ],
    verify: (_) =>
        verify(() => repository.save(allOn.copyWith(income: false))).called(1),
  );

  blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
    'ошибка сохранения — откат переключателя и failure для тоста',
    setUp: () =>
        when(() => repository.save(any())).thenThrow(const NetworkFailure()),
    build: build,
    seed: () => const NotificationPreferencesState.loaded(allOn),
    act: (cubit) => cubit.toggle(.budget, false),
    expect: () => [
      NotificationPreferencesState.loaded(allOn.copyWith(budget: false)),
      const NotificationPreferencesState.loaded(
        allOn,
        failure: NetworkFailure(),
      ),
    ],
  );

  test(
    'откат одного переключателя не трогает соседний, сменённый позже',
    () async {
      final first = Completer<NotificationPreferences>();
      when(() => repository.save(allOn.copyWith(budget: false)))
          .thenAnswer((_) => first.future);
      when(() => repository.save(allOn.copyWith(budget: false, goal: false)))
          .thenAnswer((_) async => allOn.copyWith(budget: false, goal: false));
      final cubit = build()
        ..emit(const NotificationPreferencesState.loaded(allOn));

      final budget = cubit.toggle(.budget, false);
      await cubit.toggle(.goal, false);
      first.completeError(const NetworkFailure());
      await budget;

      expect(
        cubit.state,
        NotificationPreferencesState.loaded(
          allOn.copyWith(goal: false),
          failure: const NetworkFailure(),
        ),
      );
      await cubit.close();
    },
  );

  blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
    'до загрузки toggle ничего не делает',
    build: build,
    act: (cubit) => cubit.toggle(.goal, false),
    expect: () => <NotificationPreferencesState>[],
    verify: (_) => verifyNever(() => repository.save(any())),
  );
}
