import 'package:spendyholik/core/models/currency.dart';

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/debts/data/models/debt_model.dart';
import 'package:spendyholik/features/debts/data/repositories/debt_repository.dart';
import 'package:spendyholik/features/debts/presentation/cubit/debt_detail_cubit.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

DebtModel debt({int remaining = 1200000}) => DebtModel(
  currency: Currency.rub,
  id: 'dmitry',
  counterparty: 'Дмитрий',
  direction: DebtDirection.iOwe,
  total: 1200000,
  remaining: remaining,
  createdAt: DateTime(2026, 10, 24),
);

void main() {
  late MockDebtRepository repository;
  late MockDataChangeBus bus;
  late StreamController<Set<DataTopic>> changes;

  final dmitry = debt();

  setUp(() {
    repository = MockDebtRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
    when(() => repository.getHistory('dmitry')).thenAnswer((_) async => []);
  });

  tearDown(() => changes.close());

  DebtDetailCubit build() => DebtDetailCubit(repository, bus);

  blocTest<DebtDetailCubit, DebtDetailState>(
    'загрузка: loading → долг и история',
    setUp: () =>
        when(() => repository.getDebt('dmitry'))
            .thenAnswer((_) async => dmitry),
    build: build,
    act: (cubit) => cubit.load('dmitry'),
    expect: () => [
      const DebtDetailState.loading(),
      DebtDetailState.loaded(dmitry, const []),
    ],
  );

  blocTest<DebtDetailCubit, DebtDetailState>(
    'долга нет — error',
    setUp: () =>
        when(() => repository.getDebt('dmitry'))
            .thenThrow(const NotFoundFailure()),
    build: build,
    act: (cubit) => cubit.load('dmitry'),
    expect: () => [
      const DebtDetailState.loading(),
      const DebtDetailState.error(NotFoundFailure()),
    ],
  );

  blocTest<DebtDetailCubit, DebtDetailState>(
    'погашение в шине — тихая перезагрузка',
    setUp: () {
      var calls = 0;
      when(() => repository.getDebt('dmitry')).thenAnswer(
        (_) async => ++calls == 1 ? debt() : debt(remaining: 600000),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.load('dmitry');
      changes.add({DataTopic.debts});
      await Future<void>.delayed(Duration.zero);
    },
    skip: 2,
    expect: () => [
      isA<DebtDetailLoaded>().having(
        (s) => s.debt.remaining,
        'remaining',
        600000,
      ),
    ],
  );
}
