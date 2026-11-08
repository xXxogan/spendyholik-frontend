import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/repositories/repositories.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:spendyholik/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:spendyholik/features/transactions/presentation/widgets/transactions_section.dart';

import '../../../../helpers/pump_app.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

void main() {
  late MockTransactionRepository repository;

  setUpAll(() => registerFallbackValue(const TransactionFilter()));

  setUp(() {
    repository = MockTransactionRepository();
    final bus = MockDataChangeBus();
    when(() => bus.changes).thenAnswer((_) => const Stream.empty());
    when(() => repository.getPage(any()))
        .thenAnswer((_) async => TransactionPage(items: []));
    getIt.registerFactory(() => TransactionsCubit(repository, bus));
  });

  tearDown(() => getIt.unregister<TransactionsCubit>());

  testWidgets('сменился фильтр (правка бюджета) — данные по новому фильтру', (
    tester,
  ) async {
    const food = TransactionFilter(categoryId: 'food');
    const cafe = TransactionFilter(categoryId: 'cafe');
    // Тот же ключ, что даёт TwoColumnLayout: секция не пересоздаётся.
    final key = GlobalKey();

    await pumpPage(
      tester,
      TransactionsSection(key: key, filter: food, title: 'Операции'),
    );
    await settle(tester);
    await pumpPage(
      tester,
      TransactionsSection(key: key, filter: cafe, title: 'Операции'),
    );
    await settle(tester);

    verify(() => repository.getPage(cafe)).called(1);
  });

  testWidgets('операция — в валюте своего счёта, а не в базовой', (
    tester,
  ) async {
    when(() => repository.getPage(any())).thenAnswer(
      (_) async => TransactionPage(
        items: [
          TransactionModel(
            id: 't1',
            type: TransactionType.expense,
            amount: 10000,
            title: 'Кофе',
            account: const AccountRef(
              id: 'usd',
              name: 'Доллары',
              color: EntityColor.green,
            ),
            occurredAt: DateTime(2026, 11, 7, 12),
            currency: Currency.usd,
          ),
        ],
      ),
    );

    await pumpPage(
      tester,
      const CurrencyScope(
        currency: Currency.rub,
        child: TransactionsSection(
          filter: TransactionFilter(),
          title: 'Операции',
        ),
      ),
    );
    await settle(tester);

    expect(find.textContaining(r'$'), findsOneWidget);
    expect(find.textContaining('₽'), findsNothing);
  });

  testWidgets('sliver: длинный список строит только видимые строки', (
    tester,
  ) async {
    final transactions = [
      for (var i = 0; i < 200; i++)
        TransactionModel(
          currency: Currency.rub,
          id: 't$i',
          type: TransactionType.expense,
          amount: 10000,
          title: 't$i',
          account: const AccountRef(
            id: 'card',
            name: 'Карта',
            color: EntityColor.blue,
          ),
          occurredAt: DateTime(2026, 11, 7, 12).subtract(Duration(hours: i)),
        ),
    ];
    when(() => repository.getPage(any()))
        .thenAnswer((_) async => TransactionPage(items: transactions));

    await pumpPage(
      tester,
      const CurrencyScope(
        currency: Currency.rub,
        child: CustomScrollView(
          slivers: [
            TransactionsSection.sliver(
              filter: TransactionFilter(accountId: 'card'),
              title: 'Операции',
            ),
          ],
        ),
      ),
    );
    await settle(tester);

    final built = find.byType(TransactionTile).evaluate().length;
    expect(built, greaterThan(0));
    expect(built, lessThan(50));
  });

  group('подгрузка', () {
    final first = [
      for (var i = 0; i < 60; i++)
        TransactionModel(
          currency: Currency.rub,
          id: 't$i',
          type: TransactionType.expense,
          amount: 10000,
          title: 't$i',
          account: const AccountRef(
            id: 'card',
            name: 'Карта',
            color: EntityColor.blue,
          ),
          occurredAt: DateTime(2026, 11, 7, 12).subtract(Duration(hours: i)),
        ),
    ];

    Future<void> pumpSection(
      WidgetTester tester, {
      required bool sliver,
      bool moreFails = false,
    }) async {
      when(
        () => repository.getPage(any()),
      ).thenAnswer((_) async => TransactionPage(items: first, nextCursor: 'c'));
      final more = when(
        () => repository.getPage(
          any(),
          cursor: any(named: 'cursor', that: isNotNull),
        ),
      );
      if (moreFails) {
        more.thenThrow(const NetworkFailure());
      } else {
        more.thenAnswer((_) async => TransactionPage(items: []));
      }
      const filter = TransactionFilter(accountId: 'card');
      await pumpPage(
        tester,
        CurrencyScope(
          currency: Currency.rub,
          child: sliver
              ? const CustomScrollView(
                  slivers: [
                    TransactionsSection.sliver(
                      filter: filter,
                      title: 'Операции',
                    ),
                  ],
                )
              : const SingleChildScrollView(
                  child: TransactionsSection(filter: filter, title: 'Операции'),
                ),
        ),
      );
      await settle(tester);
    }

    testWidgets('sliver: прокрутка к концу грузит следующую страницу', (
      tester,
    ) async {
      await pumpSection(tester, sliver: true);
      verifyNever(
        () => repository.getPage(
          any(),
          cursor: any(named: 'cursor', that: isNotNull),
        ),
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await settle(tester);

      verify(() => repository.getPage(any(), cursor: 'c')).called(1);
    });

    testWidgets('sliver: страница не загрузилась — повтор только по кнопке', (
      tester,
    ) async {
      await pumpSection(tester, sliver: true, moreFails: true);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await settle(tester);
      await settle(tester);

      verify(() => repository.getPage(any(), cursor: 'c')).called(1);
      expect(find.text('Не удалось загрузить'), findsOneWidget);
    });

    testWidgets('плоская секция Главной страницы не подгружает', (
      tester,
    ) async {
      await pumpSection(tester, sliver: false);

      verifyNever(
        () => repository.getPage(
          any(),
          cursor: any(named: 'cursor', that: isNotNull),
        ),
      );
    });
  });
}
