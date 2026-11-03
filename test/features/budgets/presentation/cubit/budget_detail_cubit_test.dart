import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/budgets/data/models/budget_model.dart';
import 'package:spendyholik/features/budgets/data/repositories/budget_repository.dart';
import 'package:spendyholik/features/budgets/presentation/cubit/budget_detail_cubit.dart';
import 'package:spendyholik/features/categories/categories.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

BudgetModel budget({int spent = 700000}) => BudgetModel(
  id: 'food',
  category: const CategoryRef(
    id: 'cat-food',
    name: 'Продукты',
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

  final before = budget();
  final after = budget(spent: 900000);

  setUp(() {
    repository = MockBudgetRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  BudgetDetailCubit build() => BudgetDetailCubit(repository, bus);

  blocTest<BudgetDetailCubit, BudgetDetailState>(
    'загрузка: loading → бюджет',
    setUp: () =>
        when(() => repository.getBudget('food'))
            .thenAnswer((_) async => before),
    build: build,
    act: (cubit) => cubit.load('food'),
    expect: () => [
      const BudgetDetailState.loading(),
      BudgetDetailState.loaded(before),
    ],
  );

  blocTest<BudgetDetailCubit, BudgetDetailState>(
    'бюджета нет — error с NotFoundFailure',
    setUp: () =>
        when(() => repository.getBudget('food'))
            .thenThrow(const NotFoundFailure()),
    build: build,
    act: (cubit) => cubit.load('food'),
    expect: () => [
      const BudgetDetailState.loading(),
      const BudgetDetailState.error(NotFoundFailure()),
    ],
  );

  blocTest<BudgetDetailCubit, BudgetDetailState>(
    'изменение бюджетов в шине — тихая перезагрузка',
    setUp: () {
      var calls = 0;
      when(() => repository.getBudget('food'))
          .thenAnswer((_) async => ++calls == 1 ? before : after);
    },
    build: build,
    act: (cubit) async {
      await cubit.load('food');
      changes.add({DataTopic.budgets});
      await Future<void>.delayed(Duration.zero);
    },
    skip: 2,
    expect: () => [BudgetDetailState.loaded(after)],
  );
}
