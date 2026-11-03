import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/goals/data/models/goal_model.dart';
import 'package:spendyholik/features/goals/data/repositories/goal_repository.dart';
import 'package:spendyholik/features/goals/presentation/cubit/goals_cubit.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

GoalModel goal(String id, {int saved = 0, DateTime? deadline}) => GoalModel(
  id: id,
  name: 'Цель $id',
  target: 1000000,
  saved: saved,
  deadline: deadline,
);

void main() {
  late MockGoalRepository repository;
  late MockDataChangeBus bus;
  late StreamController<Set<DataTopic>> changes;

  final buffer = goal('buffer', saved: 600000);
  final trip = goal('trip', saved: 100000, deadline: DateTime(2027, 7));

  setUp(() {
    repository = MockGoalRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  GoalsCubit build() => GoalsCubit(repository, bus);

  blocTest<GoalsCubit, GoalsState>(
    'загрузка: loading → цели',
    setUp: () =>
        when(() => repository.getGoals()).thenAnswer((_) async => [buffer]),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const GoalsState.loading(),
      GoalsState.loaded([buffer]),
    ],
  );

  blocTest<GoalsCubit, GoalsState>(
    'целей нет — empty',
    setUp: () => when(() => repository.getGoals()).thenAnswer((_) async => []),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [const GoalsState.loading(), const GoalsState.empty()],
  );

  blocTest<GoalsCubit, GoalsState>(
    'ошибка репозитория — error с этой ошибкой',
    setUp: () =>
        when(() => repository.getGoals()).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const GoalsState.loading(),
      const GoalsState.error(NetworkFailure()),
    ],
  );

  blocTest<GoalsCubit, GoalsState>(
    'изменение целей в шине — тихая перезагрузка',
    setUp: () {
      var calls = 0;
      when(() => repository.getGoals())
          .thenAnswer((_) async => ++calls == 1 ? [buffer] : [buffer, trip]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      changes.add({DataTopic.budgets});
      changes.add({DataTopic.goals});
      await Future<void>.delayed(Duration.zero);
    },
    skip: 2,
    expect: () => [
      GoalsState.loaded([buffer, trip]),
    ],
    verify: (_) => verify(() => repository.getGoals()).called(2),
  );

  group('nearest', () {
    test('есть дедлайн — цель с ближайшим дедлайном', () {
      final later = goal('later', saved: 900000, deadline: DateTime(2028));

      expect(GoalsCubit.nearestOf([buffer, later, trip]), trip);
    });

    test('дедлайнов нет — наибольший progress', () {
      final small = goal('small', saved: 100000);

      expect(GoalsCubit.nearestOf([small, buffer]), buffer);
    });

    test('достигнутые пропускаются', () {
      final done = goal('done', saved: 1000000, deadline: DateTime(2026, 12));

      expect(GoalsCubit.nearestOf([done, buffer]), buffer);
    });

    test('нет целей или все достигнуты — null', () {
      expect(GoalsCubit.nearestOf([]), isNull);
      expect(GoalsCubit.nearestOf([goal('done', saved: 1000000)]), isNull);
    });

    blocTest<GoalsCubit, GoalsState>(
      'геттер nearest — по загруженным целям',
      setUp: () =>
          when(() => repository.getGoals())
              .thenAnswer((_) async => [buffer, trip]),
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.nearest, trip),
    );
  });
}
