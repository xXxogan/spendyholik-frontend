import 'package:spendyholik/core/models/currency.dart';

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/entity_color.dart';
import 'package:spendyholik/features/accounts/data/models/account_model.dart';
import 'package:spendyholik/features/accounts/data/repositories/account_repository.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/account_detail_cubit.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

void main() {
  late MockAccountRepository repository;
  late MockDataChangeBus bus;
  late StreamController<Set<DataTopic>> changes;

  const account = AccountModel(
    currency: Currency.rub,
    id: 'card',
    name: 'Карта',
    type: AccountType.debit,
    balance: 8425000,
    color: EntityColor.blue,
    isArchived: false,
  );
  final history = [
    BalancePoint(at: DateTime(2026, 9, 14), balance: 7000000),
    BalancePoint(at: DateTime(2026, 10, 19), balance: 8425000),
  ];

  setUp(() {
    repository = MockAccountRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  AccountDetailCubit build() => AccountDetailCubit(repository, bus);

  void stubLoaded() {
    when(() => repository.getAccount('card')).thenAnswer((_) async => account);
    when(() => repository.getBalanceHistory('card'))
        .thenAnswer((_) async => history);
  }

  blocTest<AccountDetailCubit, AccountDetailState>(
    'загрузка: счёт и история баланса',
    setUp: stubLoaded,
    build: build,
    act: (cubit) => cubit.load('card'),
    expect: () => [
      const AccountDetailState.loading(),
      AccountDetailState.loaded(account, history),
    ],
  );

  blocTest<AccountDetailCubit, AccountDetailState>(
    'счёта нет — error(NotFound)',
    setUp: () =>
        when(() => repository.getAccount('card'))
            .thenThrow(const NotFoundFailure()),
    build: build,
    act: (cubit) => cubit.load('card'),
    expect: () => [
      const AccountDetailState.loading(),
      const AccountDetailState.error(NotFoundFailure()),
    ],
  );

  blocTest<AccountDetailCubit, AccountDetailState>(
    'архивация — archived',
    setUp: () {
      stubLoaded();
      when(() => repository.archive('card')).thenAnswer((_) async {});
    },
    build: build,
    act: (cubit) async {
      await cubit.load('card');
      await cubit.archive();
    },
    skip: 2,
    expect: () => [const AccountDetailState.archived()],
    verify: (_) => verify(() => repository.archive('card')).called(1),
  );

  blocTest<AccountDetailCubit, AccountDetailState>(
    'ошибка архивации — error',
    setUp: () {
      stubLoaded();
      when(() => repository.archive('card')).thenThrow(const NetworkFailure());
    },
    build: build,
    act: (cubit) async {
      await cubit.load('card');
      await cubit.archive();
    },
    skip: 2,
    expect: () => [const AccountDetailState.error(NetworkFailure())],
  );

  blocTest<AccountDetailCubit, AccountDetailState>(
    'изменились операции — тихая перезагрузка',
    setUp: () {
      var calls = 0;
      when(() => repository.getAccount('card'))
          .thenAnswer((_) async => account);
      when(() => repository.getBalanceHistory('card'))
          .thenAnswer((_) async => ++calls == 1 ? history : history.sublist(1));
    },
    build: build,
    act: (cubit) async {
      await cubit.load('card');
      changes.add({DataTopic.transactions});
      await Future<void>.delayed(Duration.zero);
    },
    skip: 2,
    expect: () => [AccountDetailState.loaded(account, history.sublist(1))],
    verify: (_) => verify(() => repository.getAccount('card')).called(2),
  );

  blocTest<AccountDetailCubit, AccountDetailState>(
    'возврат из архива — снова loaded с активным счётом, со страницы не уходим',
    setUp: () {
      var calls = 0;
      when(() => repository.getAccount('card')).thenAnswer(
        (_) async =>
            ++calls == 1 ? account.copyWith(isArchived: true) : account,
      );
      when(() => repository.getBalanceHistory('card'))
          .thenAnswer((_) async => history);
      when(() => repository.unarchive('card')).thenAnswer((_) async {});
    },
    build: build,
    act: (cubit) async {
      await cubit.load('card');
      await cubit.unarchive();
    },
    skip: 2,
    expect: () => [
      isA<AccountDetailLoaded>().having(
        (s) => s.account.isArchived,
        'isArchived',
        isFalse,
      ),
    ],
    verify: (_) => verify(() => repository.unarchive('card')).called(1),
  );

  blocTest<AccountDetailCubit, AccountDetailState>(
    'ошибка возврата из архива — error',
    setUp: () {
      stubLoaded();
      when(() => repository.unarchive('card'))
          .thenThrow(const NetworkFailure());
    },
    build: build,
    act: (cubit) async {
      await cubit.load('card');
      await cubit.unarchive();
    },
    skip: 2,
    expect: () => [const AccountDetailState.error(NetworkFailure())],
  );
}
