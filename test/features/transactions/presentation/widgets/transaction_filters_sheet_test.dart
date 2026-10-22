import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transaction_filters_cubit.dart';
import 'package:spendyholik/features/transactions/presentation/widgets/transaction_filters_sheet.dart';

import '../../../../helpers/pump_app.dart';

class MockTransactionFiltersCubit extends MockCubit<TransactionFiltersState>
    implements TransactionFiltersCubit {}

void main() {
  late MockTransactionFiltersCubit cubit;

  const food = CategoryModel(
    id: 'food',
    name: 'Продукты',
    kind: CategoryKind.expense,
    icon: EntityIcon.cart,
    color: EntityColor.green,
    transactionCount: 0,
  );
  const card = AccountModel(
    id: 'card',
    name: 'Карта Тинькофф',
    type: AccountType.debit,
    balance: 0,
    color: EntityColor.yellow,
    isArchived: false,
  );
  const ready = TransactionFiltersState(
    filter: TransactionFilter(type: .expense, categoryId: 'food'),
    categories: [food],
    accounts: [card],
    isLoading: false,
  );

  setUp(() => cubit = MockTransactionFiltersCubit());

  Future<void> pump(
    WidgetTester tester,
    ValueChanged<TransactionFilter?> onResult,
  ) async {
    when(() => cubit.state).thenReturn(ready);
    await pumpPage(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async => onResult(
              await Navigator.of(context).push<TransactionFilter>(
                MaterialPageRoute(
                  builder: (_) => Material(
                    child: BlocProvider<TransactionFiltersCubit>.value(
                      value: cubit,
                      child: const TransactionFiltersView(),
                    ),
                  ),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  testWidgets('варианты: категории и счета чипами', (tester) async {
    await pump(tester, (_) {});

    expect(find.text('Продукты'), findsOneWidget);
    expect(find.text('Карта Тинькофф'), findsOneWidget);
  });

  testWidgets('«Применить» возвращает черновик фильтра', (tester) async {
    TransactionFilter? result;
    await pump(tester, (filter) => result = filter);

    await tester.ensureVisible(find.text('Применить'));
    await tester.tap(find.text('Применить'));
    await settle(tester);

    expect(result, ready.filter);
  });

  testWidgets('чип счёта вызывает setAccount', (tester) async {
    await pump(tester, (_) {});

    await tester.tap(find.text('Карта Тинькофф'));

    verify(() => cubit.setAccount('card')).called(1);
  });

  testWidgets('«Сбросить» вызывает reset', (tester) async {
    await pump(tester, (_) {});

    await tester.tap(find.text('Сбросить'));

    verify(() => cubit.reset()).called(1);
  });

  group('pickerRangeFor', () {
    final first = DateTime(2016);
    final last = DateTime(2026, 10, 22);

    test('нет периода — нет начального диапазона', () {
      expect(pickerRangeFor(null, first, last), isNull);
    });

    test('месяц целиком — конец обрезан до сегодня', () {
      final range = pickerRangeFor(
        DatePeriod(start: DateTime(2026, 10), end: DateTime(2026, 11)),
        first,
        last,
      );

      expect(range!.start, DateTime(2026, 10));
      expect(range.end, last);
    });

    test('прошлый диапазон — конец включительно, последний день', () {
      final range = pickerRangeFor(
        DatePeriod(start: DateTime(2026, 3, 1), end: DateTime(2026, 3, 16)),
        first,
        last,
      );

      expect(range!.end, DateTime(2026, 3, 15));
    });

    test('начало раньше первой даты — обрезано', () {
      final range = pickerRangeFor(
        DatePeriod(start: DateTime(2010), end: DateTime(2011)),
        first,
        last,
      );

      expect(range!.start, first);
      expect(range.end, first);
    });
  });
}
