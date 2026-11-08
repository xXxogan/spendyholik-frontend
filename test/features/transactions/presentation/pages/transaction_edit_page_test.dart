import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/repositories.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/data/repositories/repositories.dart';
import 'package:spendyholik/features/categories/presentation/cubit/category_picker_cubit.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:spendyholik/features/transactions/presentation/pages/transaction_edit_page.dart';

import '../../../../helpers/pump_app.dart';

class MockTransactionFormCubit extends MockCubit<TransactionFormState>
    implements TransactionFormCubit {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

void main() {
  late MockTransactionFormCubit cubit;

  setUpAll(() => registerFallbackValue(TransactionType.expense));

  // Пикеры категорий и счетов берут свои Cubit из DI.
  setUp(() {
    cubit = MockTransactionFormCubit();
    final categories = MockCategoryRepository();
    final accounts = MockAccountRepository();
    final bus = MockDataChangeBus();
    when(() => bus.changes).thenAnswer((_) => const Stream.empty());
    when(() => categories.getCategories(kind: any(named: 'kind'))).thenAnswer(
      (_) async => const [
        CategoryModel(
          id: 'food',
          name: 'Продукты',
          kind: CategoryKind.expense,
          icon: EntityIcon.cart,
          color: EntityColor.green,
          transactionCount: 0,
        ),
      ],
    );
    when(() => accounts.getAccounts()).thenAnswer(
      (_) async => const [
        AccountModel(
          currency: Currency.rub,
          id: 'card',
          name: 'Карта Тинькофф',
          type: AccountType.debit,
          balance: 1000000,
          color: EntityColor.yellow,
          isArchived: false,
        ),
      ],
    );
    getIt
      ..registerFactory(() => CategoryPickerCubit(categories))
      ..registerFactory(() => AccountsCubit(accounts, bus));
  });

  tearDown(() {
    getIt
      ..unregister<CategoryPickerCubit>()
      ..unregister<AccountsCubit>();
  });

  Future<void> pump(WidgetTester tester, TransactionFormState state) async {
    when(() => cubit.state).thenReturn(state);
    await pumpPage(
      tester,
      BlocProvider<TransactionFormCubit>.value(
        value: cubit,
        child: const TransactionEditView(),
      ),
      width: 600,
    );
    await settle(tester);
  }

  final now = DateTime(2026, 10, 23, 12);

  testWidgets('расход: заголовок, категории и счёт', (tester) async {
    await pump(
      tester,
      TransactionFormState(accountId: 'card', occurredAt: now),
    );

    expect(find.text('Новая операция'), findsWidgets);
    expect(find.text('Продукты'), findsOneWidget);
    expect(find.text('Карта Тинькофф'), findsOneWidget);
    expect(find.text('Куда'), findsNothing);
  });

  testWidgets('суффикс суммы — валюта выбранного счёта', (tester) async {
    await pump(
      tester,
      TransactionFormState(
        accountId: 'card',
        accountCurrency: Currency.usd,
        occurredAt: now,
      ),
    );

    expect(find.text(r'$'), findsOneWidget);
    expect(find.text('₽'), findsNothing);
  });

  testWidgets('счёт не выбран — суффикс из базовой валюты', (tester) async {
    await pump(tester, TransactionFormState(occurredAt: now));

    expect(find.text('₽'), findsOneWidget);
  });

  testWidgets('перевод: «Куда» вместо категорий', (tester) async {
    await pump(
      tester,
      TransactionFormState(type: .transfer, accountId: 'card', occurredAt: now),
    );

    expect(find.text('Куда'), findsOneWidget);
    expect(find.text('Продукты'), findsNothing);
  });

  testWidgets('сегмент «Доход» вызывает typeChanged', (tester) async {
    await pump(tester, TransactionFormState(occurredAt: now));

    await tester.tap(find.text('Доход'));

    verify(() => cubit.typeChanged(TransactionType.income)).called(1);
  });

  testWidgets('правка: сегменты типа неактивны', (tester) async {
    await pump(
      tester,
      TransactionFormState(transactionId: 'shop', occurredAt: now),
    );

    await tester.tap(find.text('Доход'));

    verifyNever(() => cubit.typeChanged(any()));
    final segments = tester.widget<SegmentedButton<TransactionType>>(
      find.byType(SegmentedButton<TransactionType>),
    );
    expect(segments.onSelectionChanged, isNull);
  });

  testWidgets('тап по категории вызывает categoryChanged', (tester) async {
    await pump(tester, TransactionFormState(occurredAt: now));

    await tester.tap(find.text('Продукты'));

    verify(() => cubit.categoryChanged('food')).called(1);
  });

  testWidgets('ошибки полей видны: сумма и категория', (tester) async {
    await pump(
      tester,
      TransactionFormState(
        occurredAt: now,
        fieldErrors: const {
          TransactionField.amount: FieldError.invalidAmount,
          TransactionField.categoryId: FieldError.required,
        },
      ),
    );

    expect(find.text('Некорректная сумма'), findsOneWidget);
    expect(find.text('Обязательное поле'), findsOneWidget);
  });

  testWidgets('«Сохранить» вызывает save; правка — свой заголовок', (
    tester,
  ) async {
    when(() => cubit.save()).thenAnswer((_) async {});
    await pump(
      tester,
      TransactionFormState(transactionId: 'shop', occurredAt: now),
    );

    expect(find.text('Изменить операцию'), findsWidgets);
    await tester.ensureVisible(find.text('Сохранить'));
    await tester.tap(find.text('Сохранить'));

    verify(() => cubit.save()).called(1);
  });

  testWidgets('не загрузилась — ошибка и «Повторить»', (tester) async {
    when(() => cubit.init(any())).thenAnswer((_) async {});
    await pump(
      tester,
      const TransactionFormState(
        transactionId: 'gone',
        failure: NotFoundFailure(),
      ),
    );

    expect(find.text('Сохранить'), findsNothing);
    await tester.tap(find.text('Повторить'));

    verify(() => cubit.init('gone')).called(1);
  });
}
