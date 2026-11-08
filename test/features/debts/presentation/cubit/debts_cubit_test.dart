import 'package:spendyholik/core/models/currency.dart';

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/debts/data/models/debt_model.dart';
import 'package:spendyholik/features/debts/data/repositories/debt_repository.dart';
import 'package:spendyholik/features/debts/presentation/cubit/debts_cubit.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

DebtModel debt(String id, DebtDirection direction) => DebtModel(
  currency: Currency.rub,
  id: id,
  counterparty: 'Контрагент $id',
  direction: direction,
  total: 1200000,
  remaining: 1200000,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  late MockDebtRepository repository;
  late MockDataChangeBus bus;
  late StreamController<Set<DataTopic>> changes;

  final a = debt('a', DebtDirection.iOwe);
  final b = debt('b', DebtDirection.owedToMe);
  final c = debt('c', DebtDirection.iOwe);

  setUp(() {
    repository = MockDebtRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  DebtsCubit build() => DebtsCubit(repository, bus);

  blocTest<DebtsCubit, DebtsState>(
    'загрузка: loading → только «Я должен» в порядке репозитория',
    setUp: () =>
        when(() => repository.getDebts()).thenAnswer((_) async => [a, b, c]),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const DebtsState.loading(),
      DebtsState.loaded([a, c], DebtDirection.iOwe),
    ],
  );

  blocTest<DebtsCubit, DebtsState>(
    'setDirection фильтрует кэш без второй загрузки',
    setUp: () =>
        when(() => repository.getDebts()).thenAnswer((_) async => [a, b, c]),
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.setDirection(DebtDirection.owedToMe);
    },
    skip: 2,
    expect: () => [
      DebtsState.loaded([b], DebtDirection.owedToMe),
    ],
    verify: (_) => verify(() => repository.getDebts()).called(1),
  );

  blocTest<DebtsCubit, DebtsState>(
    'пусто в направлении — empty(direction)',
    setUp: () => when(() => repository.getDebts()).thenAnswer((_) async => [a]),
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.setDirection(DebtDirection.owedToMe);
    },
    skip: 2,
    expect: () => [const DebtsState.empty(DebtDirection.owedToMe)],
  );

  blocTest<DebtsCubit, DebtsState>(
    'ошибка репозитория — error',
    setUp: () =>
        when(() => repository.getDebts()).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const DebtsState.loading(),
      const DebtsState.error(NetworkFailure()),
    ],
  );

  blocTest<DebtsCubit, DebtsState>(
    'шина debts: тихая перезагрузка без loading',
    setUp: () {
      var calls = 0;
      when(() => repository.getDebts())
          .thenAnswer((_) async => ++calls == 1 ? [a] : [a, c]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      changes.add({DataTopic.debts});
      await Future<void>.delayed(Duration.zero);
    },
    skip: 2,
    expect: () => [
      DebtsState.loaded([a, c], DebtDirection.iOwe),
    ],
  );

  blocTest<DebtsCubit, DebtsState>(
    'другая тема шины — без перезагрузки',
    setUp: () => when(() => repository.getDebts()).thenAnswer((_) async => [a]),
    build: build,
    act: (cubit) async {
      await cubit.load();
      changes.add({DataTopic.goals});
      await Future<void>.delayed(Duration.zero);
    },
    verify: (_) => verify(() => repository.getDebts()).called(1),
  );
}
