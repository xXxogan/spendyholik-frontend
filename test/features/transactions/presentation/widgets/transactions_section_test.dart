import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/app/di/injection.dart';
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
    when(() => repository.getTransactions(any())).thenAnswer((_) async => []);
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

    verify(() => repository.getTransactions(cafe)).called(1);
  });

  testWidgets('sliver: длинный список строит только видимые строки', (
    tester,
  ) async {
    final transactions = [
      for (var i = 0; i < 200; i++)
        TransactionModel(
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
    when(() => repository.getTransactions(any()))
        .thenAnswer((_) async => transactions);

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
}
