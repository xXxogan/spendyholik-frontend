import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/goals/data/models/goal_model.dart';
import 'package:spendyholik/features/goals/data/repositories/goal_repository.dart';
import 'package:spendyholik/features/goals/presentation/cubit/goal_detail_cubit.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

const _savings = AccountRef(
  id: 'acc-savings',
  name: 'Накопительный',
  color: EntityColor.green,
);

GoalContribution contribution(int amount, DateTime date) => GoalContribution(
  id: 'c-${date.millisecondsSinceEpoch}',
  amount: amount,
  from: _savings,
  date: date,
);

const _buffer = GoalModel(
  currency: Currency.rub,
  id: 'buffer',
  name: 'Подушка',
  target: 20000000,
  saved: 12000000,
);

void main() {
  final now = DateTime(2026, 11, 3, 12);

  group('forecastMonths', () {
    test('ceil(остаток / среднее за 3 месяца)', () {
      // 3 × 25 000 за 3 месяца — 25 000 в месяц; 80 000 → 3,2 → 4.
      final contributions = [
        contribution(2500000, DateTime(2026, 10, 5)),
        contribution(2500000, DateTime(2026, 9, 5)),
        contribution(2500000, DateTime(2026, 8, 5)),
        contribution(9000000, DateTime(2026, 5, 5)),
      ];

      expect(GoalDetailCubit.forecastMonths(_buffer, contributions, now), 4);
    });

    test('за 3 месяца пополнений нет — null', () {
      final old = [contribution(2500000, DateTime(2026, 6, 5))];

      expect(GoalDetailCubit.forecastMonths(_buffer, old, now), isNull);
      expect(GoalDetailCubit.forecastMonths(_buffer, const [], now), isNull);
    });

    test('цель достигнута — 0', () {
      const reached = GoalModel(
        currency: Currency.rub,
        id: 'phone',
        name: 'Телефон',
        target: 6000000,
        saved: 6000000,
      );

      expect(GoalDetailCubit.forecastMonths(reached, const [], now), 0);
    });
  });

  group('cubit', () {
    late MockGoalRepository repository;
    late MockDataChangeBus bus;
    late StreamController<Set<DataTopic>> changes;

    setUp(() {
      repository = MockGoalRepository();
      bus = MockDataChangeBus();
      changes = StreamController<Set<DataTopic>>.broadcast();
      when(() => bus.changes).thenAnswer((_) => changes.stream);
    });

    tearDown(() => changes.close());

    GoalDetailCubit build() => GoalDetailCubit(repository, bus);

    blocTest<GoalDetailCubit, GoalDetailState>(
      'загрузка: loading → цель, история, прогноз',
      setUp: () {
        when(() => repository.getGoal('buffer'))
            .thenAnswer((_) async => _buffer);
        when(() => repository.getContributions('buffer'))
            .thenAnswer((_) async => const []);
      },
      build: build,
      act: (cubit) => cubit.load('buffer'),
      expect: () => [
        const GoalDetailState.loading(),
        const GoalDetailState.loaded(_buffer, [], null),
      ],
    );

    blocTest<GoalDetailCubit, GoalDetailState>(
      'цели нет — error с NotFoundFailure',
      setUp: () =>
          when(() => repository.getGoal('buffer'))
              .thenThrow(const NotFoundFailure()),
      build: build,
      act: (cubit) => cubit.load('buffer'),
      expect: () => [
        const GoalDetailState.loading(),
        const GoalDetailState.error(NotFoundFailure()),
      ],
    );

    blocTest<GoalDetailCubit, GoalDetailState>(
      'изменение целей в шине — тихая перезагрузка',
      setUp: () {
        var calls = 0;
        when(() => repository.getGoal('buffer')).thenAnswer(
          (_) async =>
              ++calls == 1 ? _buffer : _buffer.copyWith(saved: 14000000),
        );
        when(() => repository.getContributions('buffer'))
            .thenAnswer((_) async => const []);
      },
      build: build,
      act: (cubit) async {
        await cubit.load('buffer');
        changes.add({DataTopic.goals});
        await Future<void>.delayed(Duration.zero);
      },
      skip: 2,
      expect: () => [
        isA<GoalDetailLoaded>().having((s) => s.goal.saved, 'saved', 14000000),
      ],
    );

    blocTest<GoalDetailCubit, GoalDetailState>(
      'цель удалена, пока открыта: перезагрузка по шине — deleted, а не error',
      setUp: () {
        var calls = 0;
        when(() => repository.getGoal('buffer')).thenAnswer(
          (_) async => ++calls == 1 ? _buffer : throw const NotFoundFailure(),
        );
        when(() => repository.getContributions('buffer'))
            .thenAnswer((_) async => const []);
      },
      build: build,
      act: (cubit) async {
        await cubit.load('buffer');
        changes.add({DataTopic.goals});
        await Future<void>.delayed(Duration.zero);
      },
      skip: 2,
      expect: () => [const GoalDetailState.deleted()],
    );
  });
}
