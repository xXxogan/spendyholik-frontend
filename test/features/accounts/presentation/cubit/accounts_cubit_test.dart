import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/entity_color.dart';
import 'package:spendyholik/features/accounts/data/models/account_model.dart';
import 'package:spendyholik/features/accounts/data/repositories/account_repository.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/accounts_cubit.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

AccountModel account(String id, {bool archived = false}) => AccountModel(
  id: id,
  name: 'Счёт $id',
  type: AccountType.debit,
  balance: 100000,
  color: EntityColor.blue,
  isArchived: archived,
);

void main() {
  late MockAccountRepository repository;
  late MockDataChangeBus bus;
  late StreamController<Set<DataTopic>> changes;

  final card = account('card');
  final cash = account('cash');
  final old = account('old', archived: true);

  setUp(() {
    repository = MockAccountRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  AccountsCubit build() => AccountsCubit(repository, bus);

  blocTest<AccountsCubit, AccountsState>(
    'загрузка: loading → все счета, архивные в конце',
    setUp: () =>
        when(() => repository.getAccounts())
            .thenAnswer((_) async => [old, card, cash]),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const AccountsState.loading(),
      AccountsState.loaded([card, cash, old], AccountsFilter.all),
    ],
  );

  blocTest<AccountsCubit, AccountsState>(
    'счетов нет — empty',
    setUp: () =>
        when(() => repository.getAccounts()).thenAnswer((_) async => []),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const AccountsState.loading(),
      const AccountsState.empty(AccountsFilter.all),
    ],
  );

  blocTest<AccountsCubit, AccountsState>(
    'ошибка репозитория — error с этой ошибкой',
    setUp: () =>
        when(() => repository.getAccounts()).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const AccountsState.loading(),
      const AccountsState.error(NetworkFailure()),
    ],
  );

  blocTest<AccountsCubit, AccountsState>(
    'фильтр: активные, затем архив, без повторной загрузки',
    setUp: () =>
        when(() => repository.getAccounts())
            .thenAnswer((_) async => [card, old]),
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit
        ..setFilter(AccountsFilter.active)
        ..setFilter(AccountsFilter.archived);
    },
    skip: 2,
    expect: () => [
      AccountsState.loaded([card], AccountsFilter.active),
      AccountsState.loaded([old], AccountsFilter.archived),
    ],
    verify: (_) => verify(() => repository.getAccounts()).called(1),
  );

  blocTest<AccountsCubit, AccountsState>(
    'в выбранном фильтре пусто — empty с этим фильтром',
    setUp: () =>
        when(() => repository.getAccounts()).thenAnswer((_) async => [card]),
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.setFilter(AccountsFilter.archived);
    },
    skip: 2,
    expect: () => [const AccountsState.empty(AccountsFilter.archived)],
  );

  blocTest<AccountsCubit, AccountsState>(
    'изменение счетов в шине — тихая перезагрузка без loading',
    setUp: () {
      var calls = 0;
      when(() => repository.getAccounts())
          .thenAnswer((_) async => ++calls == 1 ? [card] : [card, cash]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      changes.add({DataTopic.transactions});
      changes.add({DataTopic.accounts});
      await Future<void>.delayed(Duration.zero);
    },
    skip: 2,
    expect: () => [
      AccountsState.loaded([card, cash], AccountsFilter.all),
    ],
    verify: (_) => verify(() => repository.getAccounts()).called(2),
  );
}
