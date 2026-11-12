import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/repositories.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/account_feed_cubit.dart';
import 'package:spendyholik/features/debts/debts.dart';

class MockAccountFeedRepository extends Mock implements AccountFeedRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

FeedEntry event(String id, DateTime date) => FeedDebtEvent(
  id: id,
  date: date,
  amount: 10000,
  currency: Currency.rub,
  effect: FeedEffect.incoming,
  debtId: 'd1',
  personName: 'Иван',
  direction: DebtDirection.iOwe,
  opening: true,
);

FeedEntry contribution(String id, DateTime date) => FeedGoalContribution(
  id: id,
  date: date,
  amount: 10000,
  currency: Currency.rub,
  effect: FeedEffect.outgoing,
  goalId: 'g1',
  goalName: 'Отпуск',
);

void main() {
  late MockAccountFeedRepository repository;
  late MockDataChangeBus bus;
  late StreamController<Set<DataTopic>> changes;

  setUp(() {
    repository = MockAccountFeedRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  AccountFeedCubit build() => AccountFeedCubit(repository, bus);

  List<FeedDayGroup> groupsOf(AccountFeedState state) =>
      (state as AccountFeedLoaded).groups;

  void stubFirst(FeedPage page) =>
      when(() => repository.getPage('a1')).thenAnswer((_) async => page);

  blocTest<AccountFeedCubit, AccountFeedState>(
    'группы по дням в порядке сервера, курсор',
    setUp: () => stubFirst(
      FeedPage(
        items: [
          event('e1', DateTime(2026, 11, 10)),
          contribution('c1', DateTime(2026, 11, 10)),
          event('e2', DateTime(2026, 11, 8)),
        ],
        nextCursor: 'c2',
      ),
    ),
    build: build,
    act: (cubit) => cubit.load('a1'),
    expect: () => [const AccountFeedState.loading(), isA<AccountFeedLoaded>()],
    verify: (cubit) {
      final groups = groupsOf(cubit.state);
      expect(groups.map((g) => g.day), [
        DateTime(2026, 11, 10),
        DateTime(2026, 11, 8),
      ]);
      expect(groups.first.items.map((e) => e.id), ['e1', 'c1']);
      expect((cubit.state as AccountFeedLoaded).nextCursor, 'c2');
    },
  );

  blocTest<AccountFeedCubit, AccountFeedState>(
    'пусто — empty; ошибка — error',
    setUp: () =>
        when(() => repository.getPage(any()))
            .thenAnswer((_) async => const FeedPage(items: [])),
    build: build,
    act: (cubit) async {
      await cubit.load('a1');
      when(() => repository.getPage(any())).thenThrow(const NetworkFailure());
      await cubit.load('a1');
    },
    expect: () => [
      const AccountFeedState.loading(),
      const AccountFeedState.empty(),
      const AccountFeedState.error(NetworkFailure()),
    ],
  );

  test('следующая страница: стык дня в одной группе, без дублей', () async {
    stubFirst(
      FeedPage(
        items: [
          event('e1', DateTime(2026, 11, 10)),
          event('e2', DateTime(2026, 11, 9)),
        ],
        nextCursor: 'c2',
      ),
    );
    when(() => repository.getPage('a1', cursor: 'c2')).thenAnswer(
      (_) async => FeedPage(
        items: [
          // Сервер сдвинул границу страницы: e2 пришла второй раз.
          event('e2', DateTime(2026, 11, 9)),
          contribution('c1', DateTime(2026, 11, 9)),
          // Тот же id, но другой вид записи — не дубль.
          contribution('e1', DateTime(2026, 11, 7)),
        ],
      ),
    );
    final cubit = build();
    await cubit.load('a1');

    await cubit.loadMore();

    final state = cubit.state as AccountFeedLoaded;
    expect(state.nextCursor, isNull);
    expect(state.groups.map((g) => g.day), [
      DateTime(2026, 11, 10),
      DateTime(2026, 11, 9),
      DateTime(2026, 11, 7),
    ]);
    expect(state.groups[1].items.map((e) => e.id), ['e2', 'c1']);
    await cubit.close();
  });

  test('autoLoadMore после ошибки молчит, loadMore повторяет', () async {
    stubFirst(
      FeedPage(items: [event('e1', DateTime(2026, 11, 10))], nextCursor: 'c2'),
    );
    when(() => repository.getPage('a1', cursor: 'c2'))
        .thenThrow(const NetworkFailure());
    final cubit = build();
    await cubit.load('a1');

    await cubit.autoLoadMore();
    expect(
      (cubit.state as AccountFeedLoaded).moreFailure,
      const NetworkFailure(),
    );
    await cubit.autoLoadMore();
    verify(() => repository.getPage('a1', cursor: 'c2')).called(1);

    await cubit.loadMore();
    verify(() => repository.getPage('a1', cursor: 'c2')).called(1);
    await cubit.close();
  });

  for (final topic in [
    DataTopic.transactions,
    DataTopic.accounts,
    DataTopic.goals,
    DataTopic.debts,
  ]) {
    test('шина ${topic.name} — заново первая страница', () async {
      stubFirst(
        FeedPage(
          items: [event('e1', DateTime(2026, 11, 10))],
          nextCursor: 'c2',
        ),
      );
      when(() => repository.getPage('a1', cursor: 'c2')).thenAnswer(
        (_) async => FeedPage(items: [event('e2', DateTime(2026, 11, 9))]),
      );
      final cubit = build();
      await cubit.load('a1');
      await cubit.loadMore();

      changes.add({topic});
      await pumpEventQueue();

      verify(() => repository.getPage('a1')).called(2);
      final state = cubit.state as AccountFeedLoaded;
      expect(state.groups.expand((g) => g.items).map((e) => e.id), ['e1']);
      expect(state.nextCursor, 'c2');
      await cubit.close();
    });
  }

  test('шина categories ленту не трогает', () async {
    stubFirst(FeedPage(items: [event('e1', DateTime(2026, 11, 10))]));
    final cubit = build();
    await cubit.load('a1');

    changes.add({DataTopic.categories});
    await pumpEventQueue();

    verify(() => repository.getPage('a1')).called(1);
    await cubit.close();
  });

  test('страница, запрошенная до перезагрузки, не дописывается', () async {
    stubFirst(
      FeedPage(items: [event('e1', DateTime(2026, 11, 10))], nextCursor: 'c2'),
    );
    final stale = Completer<FeedPage>();
    when(() => repository.getPage('a1', cursor: 'c2'))
        .thenAnswer((_) => stale.future);
    final cubit = build();
    await cubit.load('a1');

    final more = cubit.loadMore();
    await cubit.load('a1');
    stale.complete(FeedPage(items: [event('old', DateTime(2026, 11, 1))]));
    await more;

    final state = cubit.state as AccountFeedLoaded;
    expect(state.groups.expand((g) => g.items).map((e) => e.id), ['e1']);
    await cubit.close();
  });
}
