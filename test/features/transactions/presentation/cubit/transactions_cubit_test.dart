import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/repositories/repositories.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

TransactionModel tx(
  String id,
  DateTime at, {
  TransactionType type = .expense,
}) => TransactionModel(
  currency: Currency.rub,
  id: id,
  type: type,
  amount: 10000,
  title: id,
  account: const AccountRef(id: 'card', name: 'Карта', color: EntityColor.blue),
  occurredAt: at,
);

void main() {
  late MockTransactionRepository repository;
  late MockDataChangeBus bus;
  late StreamController<Set<DataTopic>> changes;

  setUpAll(() => registerFallbackValue(const TransactionFilter()));

  setUp(() {
    repository = MockTransactionRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  TransactionsCubit build() => TransactionsCubit(repository, bus);

  List<TransactionDayGroup> groupsOf(TransactionsState state) =>
      (state as TransactionsLoaded).groups;

  blocTest<TransactionsCubit, TransactionsState>(
    'группы по дням: дни по убыванию, внутри дня — по убыванию времени',
    setUp: () => when(() => repository.getTransactions(any())).thenAnswer(
      (_) async => [
        tx('morning', DateTime(2026, 10, 22, 9)),
        tx('older', DateTime(2026, 10, 20, 12)),
        tx('evening', DateTime(2026, 10, 22, 21)),
        tx('midnight', DateTime(2026, 10, 21)),
      ],
    ),
    build: build,
    act: (cubit) => cubit.load(const TransactionFilter()),
    skip: 1,
    expect: () => [isA<TransactionsLoaded>()],
    verify: (cubit) {
      final groups = groupsOf(cubit.state);
      expect(groups.map((g) => g.day), [
        DateTime(2026, 10, 22),
        DateTime(2026, 10, 21),
        DateTime(2026, 10, 20),
      ]);
      expect(groups.first.items.map((t) => t.id), ['evening', 'morning']);
    },
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'setType — запрос с типом, остальной фильтр сохранён',
    setUp: () =>
        when(() => repository.getTransactions(any()))
            .thenAnswer((_) async => [tx('a', DateTime(2026, 10, 22))]),
    build: build,
    act: (cubit) async {
      await cubit.load(const TransactionFilter(accountId: 'card'));
      await cubit.setType(.income);
    },
    verify: (cubit) {
      const expected = TransactionFilter(
        type: TransactionType.income,
        accountId: 'card',
      );
      verify(() => repository.getTransactions(expected)).called(1);
      expect((cubit.state as TransactionsLoaded).filter, expected);
    },
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'пусто — empty с фильтром',
    setUp: () =>
        when(() => repository.getTransactions(any()))
            .thenAnswer((_) async => []),
    build: build,
    act: (cubit) => cubit.load(const TransactionFilter(type: .transfer)),
    expect: () => [
      const TransactionsState.loading(),
      const TransactionsState.empty(TransactionFilter(type: .transfer)),
    ],
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'ошибка — error',
    setUp: () =>
        when(() => repository.getTransactions(any()))
            .thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(const TransactionFilter()),
    expect: () => [
      const TransactionsState.loading(),
      const TransactionsState.error(NetworkFailure()),
    ],
    verify: (_) => expect(
      getIt<Talker>().history.map((log) => log.exception ?? log.error),
      contains(isA<NetworkFailure>()),
    ),
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'изменились счета — тихая перезагрузка с тем же фильтром',
    setUp: () =>
        when(() => repository.getTransactions(any()))
            .thenAnswer((_) async => [tx('a', DateTime(2026, 10, 22))]),
    build: build,
    act: (cubit) async {
      await cubit.load(const TransactionFilter(limit: 5));
      changes.add({DataTopic.accounts});
      await Future<void>.delayed(Duration.zero);
    },
    skip: 2,
    expect: () => [isA<TransactionsLoaded>()],
    verify: (_) => verify(
      () => repository.getTransactions(const TransactionFilter(limit: 5)),
    ).called(2),
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'applyFilter заменяет фильтр целиком',
    setUp: () =>
        when(() => repository.getTransactions(any()))
            .thenAnswer((_) async => []),
    build: build,
    act: (cubit) async {
      await cubit.load(const TransactionFilter(type: .expense));
      await cubit.applyFilter(const TransactionFilter(categoryId: 'food'));
    },
    expect: () => [
      const TransactionsState.loading(),
      const TransactionsState.empty(TransactionFilter(type: .expense)),
      const TransactionsState.empty(TransactionFilter(categoryId: 'food')),
    ],
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'applyFilter с комбинацией фильтров передаёт её в репозиторий целиком',
    setUp: () =>
        when(() => repository.getTransactions(any()))
            .thenAnswer((_) async => [tx('a', DateTime(2026, 10, 22))]),
    build: build,
    act: (cubit) => cubit.applyFilter(
      TransactionFilter(
        type: .expense,
        period: DatePeriod(start: DateTime(2026, 10), end: DateTime(2026, 11)),
        categoryId: 'food',
        accountId: 'card',
      ),
    ),
    verify: (cubit) {
      final passed =
          verify(() => repository.getTransactions(captureAny())).captured.single
              as TransactionFilter;
      expect(passed.type, TransactionType.expense);
      expect(passed.period?.start, DateTime(2026, 10));
      expect(passed.categoryId, 'food');
      expect(passed.accountId, 'card');
      expect((cubit.state as TransactionsLoaded).filter, passed);
    },
  );
}
