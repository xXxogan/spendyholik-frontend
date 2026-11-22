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
    setUp: () => when(() => repository.getPage(any())).thenAnswer(
      (_) async => TransactionPage(
        items: [
          tx('morning', DateTime(2026, 10, 22, 9)),
          tx('older', DateTime(2026, 10, 20, 12)),
          tx('evening', DateTime(2026, 10, 22, 21)),
          tx('midnight', DateTime(2026, 10, 21)),
        ],
      ),
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
    setUp: () => when(() => repository.getPage(any())).thenAnswer(
      (_) async => TransactionPage(items: [tx('a', DateTime(2026, 10, 22))]),
    ),
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
      verify(() => repository.getPage(expected)).called(1);
      expect((cubit.state as TransactionsLoaded).filter, expected);
    },
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'пусто — empty с фильтром',
    setUp: () =>
        when(() => repository.getPage(any()))
            .thenAnswer((_) async => TransactionPage(items: [])),
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
        when(() => repository.getPage(any())).thenThrow(const NetworkFailure()),
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
    setUp: () => when(() => repository.getPage(any())).thenAnswer(
      (_) async => TransactionPage(items: [tx('a', DateTime(2026, 10, 22))]),
    ),
    build: build,
    act: (cubit) async {
      await cubit.load(const TransactionFilter(limit: 5));
      changes.add({DataTopic.accounts});
      await Future<void>.delayed(Duration.zero);
    },
    skip: 2,
    expect: () => [isA<TransactionsLoaded>()],
    verify: (_) =>
        verify(() => repository.getPage(const TransactionFilter(limit: 5)))
            .called(2),
  );

  test('ошибка предыдущей загрузки не заменяет новый список', () async {
    const previousFilter = TransactionFilter(type: .expense);
    const currentFilter = TransactionFilter(type: .income);
    final previousPage = Completer<TransactionPage>();
    when(() => repository.getPage(previousFilter)).thenAnswer(
      (_) => previousPage.future,
    );
    when(() => repository.getPage(currentFilter)).thenAnswer(
      (_) async => TransactionPage(items: [
        tx('income', DateTime(2026, 11, 22), type: .income),
      ]),
    );
    final cubit = build();
    addTearDown(cubit.close);

    final previousLoad = cubit.load(previousFilter);
    await cubit.load(currentFilter);
    previousPage.completeError(const NetworkFailure());
    await previousLoad;

    expect(cubit.state, isA<TransactionsLoaded>());
    expect((cubit.state as TransactionsLoaded).filter, currentFilter);
  });

  blocTest<TransactionsCubit, TransactionsState>(
    'applyFilter заменяет фильтр целиком',
    setUp: () =>
        when(() => repository.getPage(any()))
            .thenAnswer((_) async => TransactionPage(items: [])),
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
    setUp: () => when(() => repository.getPage(any())).thenAnswer(
      (_) async => TransactionPage(items: [tx('a', DateTime(2026, 10, 22))]),
    ),
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
          verify(() => repository.getPage(captureAny())).captured.single
              as TransactionFilter;
      expect(passed.type, TransactionType.expense);
      expect(passed.period?.start, DateTime(2026, 10));
      expect(passed.categoryId, 'food');
      expect(passed.accountId, 'card');
      expect((cubit.state as TransactionsLoaded).filter, passed);
    },
  );

  group('страницы', () {
    const all = TransactionFilter();
    final first = [
      tx('t1', DateTime(2026, 11, 8, 20)),
      tx('t2', DateTime(2026, 11, 7, 12)),
    ];
    // Тот же день, что последний на первой странице: стык не должен рвать день.
    final second = [
      tx('t3', DateTime(2026, 11, 7, 9)),
      tx('t4', DateTime(2026, 11, 6, 9)),
    ];

    void stubPages({Object? moreError}) {
      when(() => repository.getPage(any())).thenAnswer(
        (_) async => TransactionPage(items: first, nextCursor: 'c2'),
      );
      if (moreError != null) {
        when(() => repository.getPage(any(), cursor: 'c2'))
            .thenThrow(moreError);
      } else {
        when(() => repository.getPage(any(), cursor: 'c2'))
            .thenAnswer((_) async => TransactionPage(items: second));
      }
    }

    test('load — первая страница, курсор сохранён', () async {
      stubPages();
      final cubit = build();
      await cubit.load(all);

      final state = cubit.state as TransactionsLoaded;
      expect(state.nextCursor, 'c2');
      expect(state.loadingMore, isFalse);
      await cubit.close();
    });

    test('loadMore добавляет страницу, день на стыке — одна группа', () async {
      stubPages();
      final cubit = build();
      await cubit.load(all);
      await cubit.loadMore();

      final state = cubit.state as TransactionsLoaded;
      expect(state.nextCursor, isNull);
      expect(state.groups.map((g) => g.day), [
        DateTime(2026, 11, 8),
        DateTime(2026, 11, 7),
        DateTime(2026, 11, 6),
      ]);
      expect(state.groups[1].items.map((t) => t.id), ['t2', 't3']);
      verify(() => repository.getPage(all, cursor: 'c2')).called(1);
      await cubit.close();
    });

    test('loadMore показывает подгрузку внизу, пока страница идёт', () async {
      stubPages();
      final cubit = build();
      await cubit.load(all);
      final states = <TransactionsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadMore();
      await pumpEventQueue();
      await sub.cancel();

      expect((states.first as TransactionsLoaded).loadingMore, isTrue);
      expect((states.last as TransactionsLoaded).loadingMore, isFalse);
      await cubit.close();
    });

    test('конец списка — loadMore ничего не запрашивает', () async {
      when(() => repository.getPage(any()))
          .thenAnswer((_) async => TransactionPage(items: first));
      final cubit = build();
      await cubit.load(all);
      await cubit.loadMore();

      verify(() => repository.getPage(all)).called(1);
      verifyNoMoreInteractions(repository);
      await cubit.close();
    });

    test('повторный loadMore во время подгрузки — один запрос', () async {
      final gate = Completer<TransactionPage>();
      when(() => repository.getPage(any())).thenAnswer(
        (_) async => TransactionPage(items: first, nextCursor: 'c2'),
      );
      when(() => repository.getPage(any(), cursor: 'c2'))
          .thenAnswer((_) => gate.future);
      final cubit = build();
      await cubit.load(all);

      final a = cubit.loadMore();
      final b = cubit.loadMore();
      gate.complete(TransactionPage(items: second));
      await Future.wait([a, b]);

      verify(() => repository.getPage(all, cursor: 'c2')).called(1);
      await cubit.close();
    });

    test('ошибка loadMore — moreFailure, загруженное на месте', () async {
      stubPages(moreError: const NetworkFailure());
      final cubit = build();
      await cubit.load(all);
      await cubit.loadMore();

      final state = cubit.state as TransactionsLoaded;
      expect(state.moreFailure, isA<NetworkFailure>());
      expect(state.loadingMore, isFalse);
      expect(state.nextCursor, 'c2', reason: '«Повторить» — та же страница');
      expect(state.groups.expand((g) => g.items).map((t) => t.id), [
        't1',
        't2',
      ]);
      await cubit.close();
    });

    test('шина во время loadMore — старая страница не дописывается', () async {
      final gate = Completer<TransactionPage>();
      when(() => repository.getPage(any())).thenAnswer(
        (_) async => TransactionPage(items: first, nextCursor: 'c2'),
      );
      when(() => repository.getPage(any(), cursor: 'c2'))
          .thenAnswer((_) => gate.future);
      final cubit = build();
      await cubit.load(all);

      final more = cubit.loadMore();
      changes.add({DataTopic.transactions});
      await pumpEventQueue();
      gate.complete(TransactionPage(items: second));
      await more;

      final state = cubit.state as TransactionsLoaded;
      expect(state.groups.expand((g) => g.items).map((t) => t.id), [
        't1',
        't2',
      ]);
      expect(state.loadingMore, isFalse);
      await cubit.close();
    });

    test('autoLoadMore после ошибки молчит, loadMore — повторяет', () async {
      stubPages(moreError: const NetworkFailure());
      final cubit = build();
      await cubit.load(all);
      await cubit.loadMore();
      clearInteractions(repository);

      await cubit.autoLoadMore();
      verifyNever(() => repository.getPage(any(), cursor: 'c2'));

      await cubit.loadMore();
      verify(() => repository.getPage(all, cursor: 'c2')).called(1);
      await cubit.close();
    });

    test('autoLoadMore без ошибки — следующая страница', () async {
      stubPages();
      final cubit = build();
      await cubit.load(all);
      await cubit.autoLoadMore();

      verify(() => repository.getPage(all, cursor: 'c2')).called(1);
      await cubit.close();
    });

    test('шина — снова первая страница', () async {
      stubPages();
      final cubit = build();
      await cubit.load(all);
      await cubit.loadMore();

      changes.add({DataTopic.transactions});
      await pumpEventQueue();

      final state = cubit.state as TransactionsLoaded;
      expect(state.nextCursor, 'c2');
      expect(state.groups.expand((g) => g.items).map((t) => t.id), [
        't1',
        't2',
      ]);
      await cubit.close();
    });
  });
}
