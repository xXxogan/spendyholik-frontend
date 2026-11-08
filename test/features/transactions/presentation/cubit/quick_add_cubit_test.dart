import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/repositories.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/data/repositories/repositories.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/repositories/repositories.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/quick_add_cubit.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

CategoryModel category(
  String id,
  int count, {
  CategoryKind kind = .expense,
  String? parentId,
}) => CategoryModel(
  id: id,
  name: id,
  kind: kind,
  icon: EntityIcon.other,
  color: EntityColor.gray,
  parentId: parentId,
  transactionCount: count,
);

AccountModel account(
  String id,
  AccountType type, {
  bool archived = false,
  Currency currency = Currency.rub,
}) => AccountModel(
  currency: currency,
  id: id,
  name: id,
  type: type,
  balance: 0,
  color: EntityColor.blue,
  isArchived: archived,
);

void main() {
  late MockTransactionRepository transactions;
  late MockAccountRepository accounts;
  late MockCategoryRepository categories;

  setUpAll(
    () => registerFallbackValue(
      TransactionDraft(
        type: .expense,
        amount: 1,
        title: '',
        accountId: '',
        occurredAt: DateTime(2026),
      ),
    ),
  );

  setUp(() {
    transactions = MockTransactionRepository();
    accounts = MockAccountRepository();
    categories = MockCategoryRepository();
    when(() => categories.getCategories(kind: CategoryKind.expense)).thenAnswer(
      (_) async => [
        for (var i = 1; i <= 8; i++) category('c$i', i),
        category('sub', 100, parentId: 'c1'),
      ],
    );
    when(() => categories.getCategories(kind: CategoryKind.income))
        .thenAnswer((_) async => [category('salary', 3, kind: .income)]);
    when(() => accounts.getAccounts()).thenAnswer(
      (_) async => [
        account('cash', .cash),
        account('old', .debit, archived: true),
        account('card', .debit, currency: Currency.usd),
        account('card2', .debit),
      ],
    );
    when(() => transactions.create(any())).thenAnswer(
      (invocation) async => TransactionModel(
        currency: Currency.rub,
        id: 'new',
        type: .expense,
        amount: 1,
        title: '',
        account: const AccountRef(
          id: 'card',
          name: 'card',
          color: EntityColor.blue,
        ),
        occurredAt: DateTime(2026),
      ),
    );
  });

  Future<QuickAddCubit> ready() async {
    final cubit = QuickAddCubit(transactions, accounts, categories);
    await cubit.init();
    return cubit;
  }

  test('валюта счёта для суммы — у карты, на которую уйдёт операция', () async {
    final cubit = await ready();

    expect(cubit.state.accountCurrency, Currency.usd);
  });

  test(
    'короткий список: 6 самых используемых категорий верхнего уровня',
    () async {
      final cubit = await ready();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.categories.map((c) => c.id), [
        'c8',
        'c7',
        'c6',
        'c5',
        'c4',
        'c3',
      ]);
    },
  );

  test('смена типа — категории доходов, выбор сброшен', () async {
    final cubit = await ready();
    cubit.categoryChanged('c8');

    await cubit.typeChanged(.income);

    expect(cubit.state.categoryId, isNull);
    expect(cubit.state.categories.map((c) => c.id), ['salary']);
  });

  test('без суммы — invalidAmount, создания нет', () async {
    final cubit = await ready();
    cubit.categoryChanged('c8');

    await cubit.submit();

    expect(cubit.state.fieldErrors, {
      QuickAddField.amount: FieldError.invalidAmount,
    });
    verifyNever(() => transactions.create(any()));
  });

  test('без категории — required', () async {
    final cubit = await ready();
    cubit.amountChanged('100');

    await cubit.submit();

    expect(cubit.state.fieldErrors, {
      QuickAddField.category: FieldError.required,
    });
  });

  test(
    'валидная — success, операция на первую активную дебетовую карту',
    () async {
      final cubit = await ready();
      cubit
        ..amountChanged('1 240')
        ..categoryChanged('c8');

      await cubit.submit();

      expect(cubit.state.status, FormStatus.success);
      final draft =
          verify(() => transactions.create(captureAny())).captured.single
              as TransactionDraft;
      expect(draft.accountId, 'card');
      expect(draft.amount, 124000);
      expect(draft.categoryId, 'c8');
      expect(draft.type, TransactionType.expense);
    },
  );

  test('нет активной дебетовой карты — ошибка у счёта, создания нет', () async {
    when(() => accounts.getAccounts())
        .thenAnswer((_) async => [account('cash', .cash)]);
    final cubit = await ready();
    cubit
      ..amountChanged('100')
      ..categoryChanged('c8');

    await cubit.submit();

    expect(cubit.state.status, FormStatus.failure);
    expect(cubit.state.fieldErrors, {
      QuickAddField.account: FieldError.required,
    });
    verifyNever(() => transactions.create(any()));
  });

  test('ошибка репозитория — failure, введённое сохранено', () async {
    when(() => transactions.create(any())).thenThrow(const NetworkFailure());
    final cubit = await ready();
    cubit
      ..amountChanged('100')
      ..categoryChanged('c8');

    await cubit.submit();

    expect(cubit.state.status, FormStatus.failure);
    expect(cubit.state.failure, const NetworkFailure());
    expect(cubit.state.amount, '100');
  });
}
