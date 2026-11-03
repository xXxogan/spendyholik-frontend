import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/budgets/data/models/budget_model.dart';
import 'package:spendyholik/features/budgets/data/repositories/budget_repository.dart';
import 'package:spendyholik/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:spendyholik/features/categories/categories.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

BudgetModel budget(String id, {int spent = 0}) => BudgetModel(
  id: id,
  category: CategoryRef(
    id: 'cat-$id',
    name: 'Категория $id',
    icon: EntityIcon.cart,
    color: EntityColor.green,
  ),
  limit: 1000000,
  spent: spent,
  period: BudgetPeriod.monthly,
  currentPeriod: DatePeriod(start: DateTime(2026, 11), end: DateTime(2026, 12)),
);

void main() {
  late MockBudgetRepository repository;
  late MockDataChangeBus bus;
  late StreamController<Set<DataTopic>> changes;

  final food = budget('food', spent: 700000);
  final fun = budget('fun', spent: 900000);

  setUp(() {
    repository = MockBudgetRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  BudgetsCubit build() => BudgetsCubit(repository, bus);

  blocTest<BudgetsCubit, BudgetsState>(
    'загрузка: loading → бюджеты',
    setUp: () =>
        when(() => repository.getBudgets())
            .thenAnswer((_) async => [food, fun]),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const BudgetsState.loading(),
      BudgetsState.loaded([food, fun]),
    ],
  );

  blocTest<BudgetsCubit, BudgetsState>(
    'бюджетов нет — empty',
    setUp: () =>
        when(() => repository.getBudgets()).thenAnswer((_) async => []),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [const BudgetsState.loading(), const BudgetsState.empty()],
  );

  blocTest<BudgetsCubit, BudgetsState>(
    'ошибка репозитория — error с этой ошибкой',
    setUp: () =>
        when(() => repository.getBudgets()).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const BudgetsState.loading(),
      const BudgetsState.error(NetworkFailure()),
    ],
  );

  blocTest<BudgetsCubit, BudgetsState>(
    'изменение бюджетов в шине — тихая перезагрузка без loading',
    setUp: () {
      var calls = 0;
      when(() => repository.getBudgets())
          .thenAnswer((_) async => ++calls == 1 ? [food] : [food, fun]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      changes.add({DataTopic.accounts});
      changes.add({DataTopic.budgets});
      await Future<void>.delayed(Duration.zero);
    },
    skip: 2,
    expect: () => [
      BudgetsState.loaded([food, fun]),
    ],
    verify: (_) => verify(() => repository.getBudgets()).called(2),
  );
}
