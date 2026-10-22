import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/accounts/data/models/account_model.dart';
import 'package:spendyholik/features/accounts/data/repositories/account_repository.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/total_balance_cubit.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

void main() {
  late MockAccountRepository repository;
  late MockDataChangeBus bus;
  late StreamController<Set<DataTopic>> changes;

  const balance = TotalBalance(total: 23005000, monthDelta: 4440000);
  const updated = TotalBalance(total: 22880000, monthDelta: 4315000);

  setUp(() {
    repository = MockAccountRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  TotalBalanceCubit build() => TotalBalanceCubit(repository, bus);

  blocTest<TotalBalanceCubit, TotalBalanceState>(
    'загрузка: loading → loaded',
    setUp: () => when(() => repository.getTotalBalance()).thenAnswer((_) async => balance),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [const TotalBalanceState.loading(), const TotalBalanceState.loaded(balance)],
  );

  blocTest<TotalBalanceCubit, TotalBalanceState>(
    'ошибка репозитория — error',
    setUp: () => when(() => repository.getTotalBalance()).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const TotalBalanceState.loading(),
      const TotalBalanceState.error(NetworkFailure()),
    ],
  );

  blocTest<TotalBalanceCubit, TotalBalanceState>(
    'изменились операции или счета — тихая перезагрузка, чужие темы игнорируются',
    setUp: () {
      var calls = 0;
      when(() => repository.getTotalBalance()).thenAnswer(
        (_) async => ++calls == 1 ? balance : updated,
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      changes.add({DataTopic.goals});
      changes.add({DataTopic.transactions});
      await Future<void>.delayed(Duration.zero);
    },
    skip: 2,
    expect: () => [const TotalBalanceState.loaded(updated)],
    verify: (_) => verify(() => repository.getTotalBalance()).called(2),
  );
}
