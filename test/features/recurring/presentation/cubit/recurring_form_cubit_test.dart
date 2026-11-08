import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/categories/categories.dart';
import 'package:spendyholik/features/recurring/data/models/models.dart';
import 'package:spendyholik/features/recurring/data/repositories/repositories.dart';
import 'package:spendyholik/features/recurring/presentation/cubit/recurring_form_cubit.dart';
import 'package:spendyholik/features/transactions/transactions.dart';

class MockRecurringRepository extends Mock implements RecurringRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  late MockRecurringRepository repository;
  late MockAccountRepository accounts;

  final existing = RecurringModel(
    currency: Currency.rub,
    id: 'r1',
    title: 'Интернет',
    type: TransactionType.expense,
    amount: 80000,
    category: const CategoryRef(
      id: 'cat-home',
      name: 'Дом',
      icon: EntityIcon.cart,
      color: EntityColor.green,
    ),
    account: const AccountRef(
      id: 'acc-1',
      name: 'Карта',
      color: EntityColor.blue,
    ),
    frequency: RecurrenceFrequency.weekly,
    anchor: DateTime(2026, 1, 5, 12),
    nextDate: DateTime(2026, 11, 9, 12),
    isPaused: false,
  );

  setUpAll(
    () => registerFallbackValue(
      RecurringDraft(
        title: '',
        type: TransactionType.expense,
        amount: 0,
        categoryId: '',
        accountId: '',
        frequency: RecurrenceFrequency.monthly,
        anchor: DateTime(2026),
      ),
    ),
  );

  setUp(() {
    repository = MockRecurringRepository();
    accounts = MockAccountRepository();
    when(() => accounts.getAccounts()).thenAnswer(
      (_) async => const [
        AccountModel(
          currency: Currency.usd,
          id: 'acc-usd',
          name: 'Доллары',
          type: AccountType.cash,
          balance: 0,
          color: EntityColor.green,
          isArchived: false,
        ),
      ],
    );
  });

  RecurringFormCubit build() => RecurringFormCubit(repository, accounts);

  final filled = RecurringFormState(
    title: ' Интернет ',
    amount: '800',
    categoryId: 'cat-home',
    accountId: 'acc-1',
    anchor: DateTime(2026, 11, 3, 12),
  );

  blocTest<RecurringFormCubit, RecurringFormState>(
    'пустая форма: все ошибки разом, в репозиторий не идём',
    build: build,
    seed: () => RecurringFormState(anchor: DateTime(2026, 11, 3, 12)),
    act: (cubit) => cubit.save(),
    expect: () => [
      RecurringFormState(
        anchor: DateTime(2026, 11, 3, 12),
        fieldErrors: const {
          RecurringField.title: FieldError.required,
          RecurringField.amount: FieldError.invalidAmount,
          RecurringField.categoryId: FieldError.required,
          RecurringField.accountId: FieldError.required,
        },
      ),
    ],
    verify: (_) {
      verifyNever(() => repository.create(any()));
      verifyNever(() => repository.update(any(), any()));
    },
  );

  blocTest<RecurringFormCubit, RecurringFormState>(
    'сумма 0 — invalidAmount',
    build: build,
    seed: () => filled.copyWith(amount: '0'),
    act: (cubit) => cubit.save(),
    expect: () => [
      filled.copyWith(
        amount: '0',
        fieldErrors: const {RecurringField.amount: FieldError.invalidAmount},
      ),
    ],
    verify: (_) => verifyNever(() => repository.create(any())),
  );

  blocTest<RecurringFormCubit, RecurringFormState>(
    'смена типа сбрасывает категорию',
    build: build,
    seed: () => filled,
    act: (cubit) => cubit.typeChanged(TransactionType.income),
    expect: () => [
      filled.copyWith(type: TransactionType.income, categoryId: null),
    ],
  );

  test('start: якорь — сегодня 12:00', () {
    final cubit = build()..start(DateTime(2026, 11, 3, 17, 45));
    expect(cubit.state.anchor, DateTime(2026, 11, 3, 12));
  });

  test('anchorChanged сохраняет время якоря', () {
    final cubit = build()
      ..start(DateTime(2026, 11, 3))
      ..anchorChanged(DateTime(2027, 2, 1));
    expect(cubit.state.anchor, DateTime(2027, 2, 1, 12));
  });

  group('превью следующего выполнения', () {
    final base = RecurringFormState(anchor: DateTime(2026, 1, 31, 12));
    final now = DateTime(2026, 2, 10);

    test('monthly — последний день короткого месяца', () {
      expect(base.nextExecution(now), DateTime(2026, 2, 28, 12));
    });

    test('weekly — ближайшая дата по неделям от якоря', () {
      final state = base.copyWith(frequency: RecurrenceFrequency.weekly);
      expect(state.nextExecution(now), DateTime(2026, 2, 14, 12));
    });

    test('yearly — через год', () {
      final state = base.copyWith(frequency: RecurrenceFrequency.yearly);
      expect(state.nextExecution(now), DateTime(2027, 1, 31, 12));
    });

    test('frequencyChanged пересчитывает превью', () {
      final cubit = build()..anchorChanged(DateTime(2026, 1, 31));
      expect(cubit.state.nextExecution(now), DateTime(2026, 2, 28, 12));

      cubit.frequencyChanged(RecurrenceFrequency.weekly);
      expect(cubit.state.nextExecution(now), DateTime(2026, 2, 14, 12));

      cubit.frequencyChanged(RecurrenceFrequency.yearly);
      expect(cubit.state.nextExecution(now), DateTime(2027, 1, 31, 12));
    });

    test('без якоря — null', () {
      expect(const RecurringFormState().nextExecution(now), isNull);
    });
  });

  blocTest<RecurringFormCubit, RecurringFormState>(
    'правка: поля заполняются из шаблона',
    setUp: () =>
        when(() => repository.getAll()).thenAnswer((_) async => [existing]),
    build: build,
    act: (cubit) => cubit.init('r1'),
    expect: () => [
      const RecurringFormState(recurringId: 'r1', isLoading: true),
      RecurringFormState(
        recurringId: 'r1',
        title: 'Интернет',
        amount: '800',
        categoryId: 'cat-home',
        accountId: 'acc-1',
        accountCurrency: Currency.rub,
        frequency: RecurrenceFrequency.weekly,
        anchor: DateTime(2026, 1, 5, 12),
      ),
    ],
  );

  test('валюта счёта: правка — у шаблона, другой счёт — из списка', () async {
    when(() => repository.getAll()).thenAnswer((_) async => [existing]);
    final cubit = build();
    await cubit.init('r1');
    expect(cubit.state.accountCurrency, Currency.rub);

    await cubit.accountChanged('acc-usd');
    expect(cubit.state.accountId, 'acc-usd');
    expect(cubit.state.accountCurrency, Currency.usd);
  });

  test('правка: тип не меняется — сервер не принимает type в PATCH', () async {
    when(() => repository.getAll()).thenAnswer((_) async => [existing]);
    final cubit = build();
    await cubit.init('r1');
    final type = cubit.state.type;

    cubit.typeChanged(type == TransactionType.expense ? .income : .expense);

    expect(cubit.state.type, type);
  });

  test('создание: валюта появляется после выбора счёта', () async {
    final cubit = build()..start(DateTime(2026, 11, 3));
    expect(cubit.state.accountCurrency, isNull);

    await cubit.accountChanged('acc-usd');
    expect(cubit.state.accountCurrency, Currency.usd);
  });

  blocTest<RecurringFormCubit, RecurringFormState>(
    'правка шаблона без категории: категория не выбрана',
    setUp: () => when(() => repository.getAll()).thenAnswer(
      (_) async => [
        RecurringModel(
          currency: Currency.rub,
          id: 'r2',
          title: 'Без категории',
          type: TransactionType.expense,
          amount: 100,
          category: const CategoryRef(
            id: '',
            name: '',
            icon: EntityIcon.other,
            color: EntityColor.gray,
          ),
          account: existing.account,
          frequency: RecurrenceFrequency.monthly,
          anchor: DateTime(2026, 1, 5, 12),
          nextDate: DateTime(2026, 11, 9, 12),
          isPaused: false,
        ),
      ],
    ),
    build: build,
    act: (cubit) => cubit.init('r2'),
    verify: (cubit) => expect(cubit.state.categoryId, isNull),
  );

  blocTest<RecurringFormCubit, RecurringFormState>(
    'правка неизвестного id — failure и loadFailed',
    setUp: () =>
        when(() => repository.getAll()).thenAnswer((_) async => [existing]),
    build: build,
    act: (cubit) => cubit.init('nope'),
    expect: () => [
      const RecurringFormState(recurringId: 'nope', isLoading: true),
      const RecurringFormState(recurringId: 'nope', failure: NotFoundFailure()),
    ],
    verify: (cubit) => expect(cubit.state.loadFailed, isTrue),
  );

  blocTest<RecurringFormCubit, RecurringFormState>(
    'успех: create с черновиком, затем success',
    setUp: () =>
        when(() => repository.create(any())).thenAnswer((_) async => existing),
    build: build,
    seed: () => filled,
    act: (cubit) => cubit.save(),
    expect: () => [
      filled.copyWith(status: FormStatus.submitting),
      filled.copyWith(status: FormStatus.success),
    ],
    verify: (_) {
      // У RecurringDraft нет ==, поэтому сверяем поля.
      final draft =
          verify(() => repository.create(captureAny())).captured.single
              as RecurringDraft;
      expect(draft.title, 'Интернет');
      expect(draft.type, TransactionType.expense);
      expect(draft.amount, 80000);
      expect(draft.categoryId, 'cat-home');
      expect(draft.accountId, 'acc-1');
      expect(draft.frequency, RecurrenceFrequency.monthly);
      expect(draft.anchor, DateTime(2026, 11, 3, 12));
    },
  );

  blocTest<RecurringFormCubit, RecurringFormState>(
    'ошибка репозитория — status failure',
    setUp: () =>
        when(() => repository.create(any())).thenThrow(const NetworkFailure()),
    build: build,
    seed: () => filled,
    act: (cubit) => cubit.save(),
    expect: () => [
      filled.copyWith(status: FormStatus.submitting),
      filled.copyWith(
        status: FormStatus.failure,
        failure: const NetworkFailure(),
      ),
    ],
  );
}
