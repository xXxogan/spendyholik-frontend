import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/currency_scope.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/repositories.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/account_feed_cubit.dart';
import 'package:spendyholik/features/accounts/presentation/widgets/account_feed_section.dart';
import 'package:spendyholik/features/accounts/presentation/widgets/feed_event_tile.dart';
import 'package:spendyholik/features/debts/debts.dart';
import 'package:spendyholik/features/transactions/transactions.dart';

import '../../../../helpers/pump_app.dart';

class MockAccountFeedRepository extends Mock implements AccountFeedRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

class MockStackRouter extends Mock implements StackRouter {}

final _day = DateTime(2026, 11, 7);

FeedEntry debtEvent(
  String id, {
  required DebtDirection direction,
  required bool opening,
  required FeedEffect effect,
  int amount = 10000,
}) => FeedDebtEvent(
  id: id,
  date: _day,
  amount: amount,
  currency: Currency.rub,
  effect: effect,
  debtId: 'd-$id',
  personName: 'Иван',
  direction: direction,
  opening: opening,
);

FeedEntry contribution() => FeedGoalContribution(
  id: 'c1',
  date: _day,
  amount: 50000,
  currency: Currency.rub,
  effect: FeedEffect.outgoing,
  goalId: 'g1',
  goalName: 'Отпуск',
);

FeedEntry operation(String id) => FeedTransaction(
  id: id,
  date: _day,
  amount: 10000,
  currency: Currency.rub,
  effect: FeedEffect.outgoing,
  transaction: TransactionModel(
    id: id,
    type: TransactionType.expense,
    amount: 10000,
    title: 'Кофе $id',
    account: const AccountRef(
      id: 'card',
      name: 'Карта',
      color: EntityColor.blue,
    ),
    occurredAt: DateTime(2026, 11, 7, 12),
    currency: Currency.rub,
  ),
);

void main() {
  late MockAccountFeedRepository repository;
  late MockStackRouter router;

  setUpAll(() => registerFallbackValue(const TabsRoute()));

  setUp(() {
    repository = MockAccountFeedRepository();
    router = MockStackRouter();
    when(() => router.push(any())).thenAnswer((_) async => null);
    final bus = MockDataChangeBus();
    when(() => bus.changes).thenAnswer((_) => const Stream.empty());
    getIt.registerFactory(() => AccountFeedCubit(repository, bus));
  });

  tearDown(getIt.reset);

  void stubFirst(List<FeedEntry> items, {String? cursor}) =>
      when(() => repository.getPage('card'))
          .thenAnswer((_) async => FeedPage(items: items, nextCursor: cursor));

  Future<void> pumpSection(WidgetTester tester) async {
    await pumpPage(
      tester,
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: const CurrencyScope(
          currency: Currency.rub,
          child: CustomScrollView(
            slivers: [
              AccountFeedSection.sliver(accountId: 'card', title: 'Операции'),
            ],
          ),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('четыре вида событий — тексты, знаки и операция', (tester) async {
    stubFirst([
      debtEvent(
        'a',
        direction: DebtDirection.iOwe,
        opening: true,
        effect: FeedEffect.incoming,
      ),
      debtEvent(
        'b',
        direction: DebtDirection.owedToMe,
        opening: true,
        effect: FeedEffect.outgoing,
      ),
      debtEvent(
        'c',
        direction: DebtDirection.iOwe,
        opening: false,
        effect: FeedEffect.outgoing,
      ),
      contribution(),
      operation('t1'),
    ]);

    await pumpSection(tester);

    expect(find.text('Получение займа · Иван'), findsOneWidget);
    expect(find.text('Выдача займа · Иван'), findsOneWidget);
    expect(find.text('Погашение долга · Иван'), findsOneWidget);
    expect(find.text('Пополнение цели · Отпуск'), findsOneWidget);
    expect(find.text('Кофе t1'), findsOneWidget);
    expect(find.byType(FeedEventTile), findsNWidgets(4));
  });

  testWidgets('знак суммы — по effect', (tester) async {
    stubFirst([
      debtEvent(
        'a',
        direction: DebtDirection.iOwe,
        opening: true,
        effect: FeedEffect.incoming,
      ),
      contribution(),
    ]);

    await pumpSection(tester);

    expect(find.textContaining('+100'), findsOneWidget);
    expect(find.textContaining('−500'), findsOneWidget);
  });

  testWidgets('нажатие на долг, цель и операцию ведёт на свой маршрут', (
    tester,
  ) async {
    stubFirst([
      debtEvent(
        'a',
        direction: DebtDirection.iOwe,
        opening: true,
        effect: FeedEffect.incoming,
      ),
      contribution(),
      operation('t1'),
    ]);
    await pumpSection(tester);

    PageRouteInfo tapped() =>
        verify(() => router.push(captureAny())).captured.single
            as PageRouteInfo;

    await tester.tap(find.text('Получение займа · Иван'));
    var route = tapped();
    expect(route.routeName, DebtDetailRoute.name);
    expect((route.args! as DebtDetailRouteArgs).debtId, 'd-a');
    clearInteractions(router);

    await tester.tap(find.text('Пополнение цели · Отпуск'));
    route = tapped();
    expect(route.routeName, GoalDetailRoute.name);
    expect((route.args! as GoalDetailRouteArgs).goalId, 'g1');
    clearInteractions(router);

    await tester.tap(find.text('Кофе t1'));
    route = tapped();
    expect(route.routeName, TransactionDetailRoute.name);
  });

  group('подгрузка', () {
    final first = [for (var i = 0; i < 60; i++) operation('t$i')];

    testWidgets('прокрутка к концу грузит следующую страницу', (tester) async {
      stubFirst(first, cursor: 'c');
      when(() => repository.getPage('card', cursor: 'c'))
          .thenAnswer((_) async => const FeedPage(items: []));
      await pumpSection(tester);
      verifyNever(() => repository.getPage('card', cursor: 'c'));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await settle(tester);

      verify(() => repository.getPage('card', cursor: 'c')).called(1);
    });

    testWidgets('ошибка страницы — «Повторить» грузит её снова', (
      tester,
    ) async {
      stubFirst(first, cursor: 'c');
      when(() => repository.getPage('card', cursor: 'c'))
          .thenThrow(const NetworkFailure());
      await pumpSection(tester);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await settle(tester);
      await settle(tester);
      verify(() => repository.getPage('card', cursor: 'c')).called(1);
      clearInteractions(repository);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await settle(tester);
      await tester.tap(find.text('Повторить'));
      await settle(tester);

      verify(() => repository.getPage('card', cursor: 'c')).called(1);
    });
  });
}
