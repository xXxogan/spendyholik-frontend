import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/repositories.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/repositories/repositories.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transaction_form_cubit.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

AccountModel account(
  String id, {
  bool archived = false,
  Currency currency = Currency.rub,
}) => AccountModel(
  currency: currency,
  id: id,
  name: id,
  type: AccountType.debit,
  balance: 1000000,
  color: EntityColor.blue,
  isArchived: archived,
);

void main() {
  late MockTransactionRepository transactions;
  late MockAccountRepository accounts;

  final at = DateTime(2026, 10, 20, 18, 42);
  final shop = TransactionModel(
    currency: Currency.rub,
    id: 'shop',
    type: .expense,
    amount: 124050,
    title: 'Пятёрочка',
    category: const CategoryRef(
      id: 'food',
      name: 'Продукты',
      icon: EntityIcon.cart,
      color: EntityColor.green,
    ),
    account: const AccountRef(
      id: 'card',
      name: 'card',
      color: EntityColor.blue,
    ),
    occurredAt: at,
    note: 'на неделю',
  );

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
    when(() => accounts.getAccounts()).thenAnswer(
      (_) async => [
        account('old', archived: true),
        account('card'),
        account('cash', currency: Currency.usd),
      ],
    );
    when(() => transactions.create(any())).thenAnswer((_) async => shop);
    when(() => transactions.update(any(), any())).thenAnswer((_) async => shop);
    when(() => transactions.getTransaction('shop'))
        .thenAnswer((_) async => shop);
  });

  Future<TransactionFormCubit> ready([
    String? id,
    TransactionType type = .expense,
  ]) async {
    final cubit = TransactionFormCubit(transactions, accounts);
    await cubit.init(id, type: type);
    return cubit;
  }

  TransactionDraft createdDraft() =>
      verify(() => transactions.create(captureAny())).captured.single
          as TransactionDraft;

  test('валюта счёта: у первого счёта, затем у выбранного', () async {
    final cubit = await ready();
    expect(cubit.state.accountCurrency, Currency.rub);

    cubit.accountChanged('cash');
    expect(cubit.state.accountCurrency, Currency.usd);
  });

  test('правка: валюта счёта операции; другой счёт — из списка', () async {
    final cubit = await ready('shop');
    expect(cubit.state.accountCurrency, Currency.rub);

    cubit.accountChanged('cash');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.accountCurrency, Currency.usd);
  });

  test('новая: первый активный счёт и текущий момент', () async {
    final before = DateTime.now();
    final cubit = await ready();

    expect(cubit.state.accountId, 'card');
    expect(cubit.state.occurredAt!.isBefore(before), isFalse);
    expect(cubit.state.isLoading, isFalse);
  });

  test('сумма пустая или 0 — invalidAmount, сохранения нет', () async {
    final cubit = await ready();
    cubit.categoryChanged('food');

    await cubit.save();
    expect(
      cubit.state.fieldErrors[TransactionField.amount],
      FieldError.invalidAmount,
    );

    cubit.amountChanged('0');
    await cubit.save();
    expect(
      cubit.state.fieldErrors[TransactionField.amount],
      FieldError.invalidAmount,
    );
    verifyNever(() => transactions.create(any()));
  });

  test('расход без категории — required у категории', () async {
    final cubit = await ready();
    cubit.amountChanged('100');

    await cubit.save();

    expect(cubit.state.fieldErrors, {
      TransactionField.categoryId: FieldError.required,
    });
  });

  test('перевод на тот же счёт — sameAccount', () async {
    final cubit = await ready(null, .transfer);
    cubit
      ..amountChanged('100')
      ..toAccountChanged('card');

    await cubit.save();

    expect(cubit.state.fieldErrors, {
      TransactionField.toAccountId: FieldError.sameAccount,
    });
  });

  test('перевод без получателя — required', () async {
    final cubit = await ready(null, .transfer);
    cubit.amountChanged('100');

    await cubit.save();

    expect(cubit.state.fieldErrors, {
      TransactionField.toAccountId: FieldError.required,
    });
  });

  test('правка поля снимает его ошибку', () async {
    final cubit = await ready();
    await cubit.save();

    cubit.amountChanged('1');

    expect(
      cubit.state.fieldErrors.containsKey(TransactionField.amount),
      isFalse,
    );
  });

  test('валидный расход — success, черновик из полей', () async {
    final cubit = await ready();
    cubit
      ..amountChanged('1 240,5')
      ..categoryChanged('food')
      ..titleChanged('  Пятёрочка ')
      ..noteChanged('   ');

    await cubit.save();

    expect(cubit.state.status, FormStatus.success);
    final draft = createdDraft();
    expect(draft.type, TransactionType.expense);
    expect(draft.amount, 124050);
    expect(draft.categoryId, 'food');
    expect(draft.accountId, 'card');
    expect(draft.title, 'Пятёрочка');
    expect(draft.note, isNull);
    expect(draft.toAccountId, isNull);
  });

  test('валидный доход — success', () async {
    final cubit = await ready(null, .income);
    cubit
      ..amountChanged('500')
      ..categoryChanged('salary');

    await cubit.save();

    expect(cubit.state.status, FormStatus.success);
    expect(createdDraft().type, TransactionType.income);
  });

  test('валидный перевод — без категории, с получателем', () async {
    final cubit = await ready();
    cubit
      ..categoryChanged('food')
      ..typeChanged(.transfer)
      ..amountChanged('5000')
      ..toAccountChanged('cash');

    await cubit.save();

    expect(cubit.state.status, FormStatus.success);
    final draft = createdDraft();
    expect(draft.categoryId, isNull);
    expect(draft.toAccountId, 'cash');
  });

  test('смена типа сбрасывает категорию и получателя', () async {
    final cubit = await ready();
    cubit
      ..categoryChanged('food')
      ..typeChanged(.income);
    expect(cubit.state.categoryId, isNull);

    cubit
      ..typeChanged(.transfer)
      ..toAccountChanged('cash')
      ..typeChanged(.expense);
    expect(cubit.state.toAccountId, isNull);
  });

  test('дата меняет день, время сохраняется', () async {
    final cubit = await ready('shop');

    cubit.dateChanged(DateTime(2026, 10, 1));

    expect(cubit.state.occurredAt, DateTime(2026, 10, 1, 18, 42));
  });

  test('init(id) заполняет форму, сохранение — update', () async {
    final cubit = await ready('shop');

    expect(cubit.state.amount, '1240.50');
    expect(cubit.state.title, 'Пятёрочка');
    expect(cubit.state.categoryId, 'food');
    expect(cubit.state.accountId, 'card');
    expect(cubit.state.occurredAt, at);
    expect(cubit.state.note, 'на неделю');

    await cubit.save();
    verify(() => transactions.update('shop', any())).called(1);
    verifyNever(() => transactions.create(any()));
  });

  test('правка: тип не меняется — сервер не принимает type в PATCH', () async {
    final cubit = await ready('shop');

    cubit.typeChanged(.income);

    expect(cubit.state.type, TransactionType.expense);
    expect(cubit.state.categoryId, 'food', reason: 'категория не сброшена');
  });

  test('init(id) неизвестной — loadFailed', () async {
    when(() => transactions.getTransaction('gone'))
        .thenThrow(const NotFoundFailure());

    final cubit = await ready('gone');

    expect(cubit.state.loadFailed, isTrue);
  });

  blocTest<TransactionFormCubit, TransactionFormState>(
    'ошибка репозитория — failure, введённое сохранено',
    setUp: () =>
        when(() => transactions.create(any()))
            .thenThrow(const NetworkFailure()),
    build: () => TransactionFormCubit(transactions, accounts),
    act: (cubit) async {
      await cubit.init(null);
      cubit
        ..amountChanged('100')
        ..categoryChanged('food');
      await cubit.save();
    },
    verify: (cubit) {
      expect(cubit.state.status, FormStatus.failure);
      expect(cubit.state.failure, const NetworkFailure());
      expect(cubit.state.amount, '100');
      expect(cubit.state.categoryId, 'food');
    },
  );
}
