import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/account_model.dart';
import 'package:spendyholik/features/categories/data/models/category_model.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transaction_detail_cubit.dart';
import 'package:spendyholik/features/transactions/presentation/pages/transaction_detail_page.dart';

import '../../../../helpers/pump_app.dart';

class MockTransactionDetailCubit extends MockCubit<TransactionDetailState>
    implements TransactionDetailCubit {}

void main() {
  late MockTransactionDetailCubit cubit;

  const card = AccountRef(id: 'a', name: 'Карта', color: EntityColor.blue);
  const deposit = AccountRef(id: 'b', name: 'Вклад', color: EntityColor.green);

  final expense = TransactionModel(
    currency: Currency.rub,
    id: 't1',
    type: TransactionType.expense,
    amount: 124000,
    title: 'Пятёрочка',
    category: const CategoryRef(
      id: 'food',
      name: 'Продукты',
      icon: EntityIcon.cart,
      color: EntityColor.green,
    ),
    account: card,
    occurredAt: DateTime(2026, 3, 12, 18, 5),
    note: 'К ужину',
  );
  final transfer = TransactionModel(
    currency: Currency.rub,
    id: 't2',
    type: TransactionType.transfer,
    amount: 500000,
    title: '',
    account: card,
    toAccount: deposit,
    occurredAt: DateTime(2026, 3, 12, 18, 5),
  );

  setUp(() => cubit = MockTransactionDetailCubit());

  Future<void> pump(WidgetTester tester, TransactionModel t) async {
    when(() => cubit.state).thenReturn(TransactionDetailState.loaded(t));
    await pumpPage(
      tester,
      BlocProvider<TransactionDetailCubit>.value(
        value: cubit,
        child: const TransactionDetailView(),
      ),
    );
    await settle(tester);
  }

  testWidgets('расход — сумма со знаком «−», категория и заметка', (
    tester,
  ) async {
    await pump(tester, expense);

    expect(find.text('−1 240 ₽'), findsOneWidget);
    expect(find.text('Категория'), findsOneWidget);
    expect(find.text('Продукты'), findsOneWidget);
    expect(find.text('К ужину'), findsOneWidget);
  });

  testWidgets('перевод — «Откуда»/«Куда», строки «Категория» нет', (
    tester,
  ) async {
    await pump(tester, transfer);

    expect(find.text('Откуда'), findsOneWidget);
    expect(find.text('Куда'), findsOneWidget);
    expect(find.text('Категория'), findsNothing);
  });

  testWidgets('«Удалить» с подтверждением вызывает delete', (tester) async {
    when(() => cubit.delete()).thenAnswer((_) async {});
    await pump(tester, expense);

    await tester.ensureVisible(find.text('Удалить'));
    await tester.tap(find.text('Удалить'));
    await settle(tester);
    expect(find.text('Удалить операцию?'), findsOneWidget);
    await tester.tap(find.text('Удалить').last);
    await settle(tester);

    verify(() => cubit.delete()).called(1);
  });

  testWidgets('отмена в диалоге — удаления нет', (tester) async {
    await pump(tester, expense);

    await tester.ensureVisible(find.text('Удалить'));
    await tester.tap(find.text('Удалить'));
    await settle(tester);
    await tester.tap(find.text('Отмена'));
    await settle(tester);

    verifyNever(() => cubit.delete());
  });
}
