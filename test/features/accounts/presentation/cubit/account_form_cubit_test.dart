import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/account_model.dart';
import 'package:spendyholik/features/accounts/data/repositories/account_repository.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/account_form_cubit.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  late MockAccountRepository repository;

  const credit = AccountModel(
    currency: Currency.rub,
    id: 'credit',
    name: 'Кредитка',
    type: AccountType.credit,
    balance: -1240050,
    color: EntityColor.red,
    isArchived: false,
    cardLast4: '1234',
    creditLimit: 15000000,
  );

  setUpAll(
    () => registerFallbackValue(
      const AccountDraft(
        name: '',
        type: AccountType.debit,
        balance: 0,
        color: EntityColor.pink,
      ),
    ),
  );

  setUp(() => repository = MockAccountRepository());

  AccountFormCubit build() => AccountFormCubit(repository);

  AccountDraft capturedCreate() =>
      verify(() => repository.create(captureAny())).captured.single
          as AccountDraft;

  blocTest<AccountFormCubit, AccountFormState>(
    'пустое имя — ошибка required, create не вызывается',
    build: build,
    act: (cubit) async {
      cubit.nameChanged('   ');
      await cubit.save();
    },
    skip: 1,
    expect: () => [
      const AccountFormState(
        name: '   ',
        fieldErrors: {AccountField.name: FieldError.required},
      ),
    ],
    verify: (_) => verifyNever(() => repository.create(any())),
  );

  blocTest<AccountFormCubit, AccountFormState>(
    'правка поля снимает его ошибку',
    build: build,
    act: (cubit) async {
      await cubit.save();
      cubit.nameChanged('Карта');
    },
    skip: 1,
    expect: () => [const AccountFormState(name: 'Карта')],
  );

  blocTest<AccountFormCubit, AccountFormState>(
    'валидная форма — submitting → success, черновик из полей',
    setUp: () =>
        when(() => repository.create(any())).thenAnswer((_) async => credit),
    build: build,
    act: (cubit) async {
      cubit
        ..nameChanged(' Наличные ')
        ..typeChanged(AccountType.cash)
        ..balanceChanged('5 000')
        ..colorChanged(EntityColor.teal);
      await cubit.save();
    },
    skip: 4,
    expect: () => [
      isA<AccountFormState>().having(
        (s) => s.status,
        'status',
        FormStatus.submitting,
      ),
      isA<AccountFormState>().having(
        (s) => s.status,
        'status',
        FormStatus.success,
      ),
    ],
    verify: (_) {
      final draft = capturedCreate();
      expect(draft.name, 'Наличные');
      expect(draft.type, AccountType.cash);
      expect(draft.balance, 500000);
      expect(draft.color, EntityColor.teal);
    },
  );

  blocTest<AccountFormCubit, AccountFormState>(
    'пустой баланс — ноль; поля чужого типа в черновик не попадают',
    setUp: () =>
        when(() => repository.create(any())).thenAnswer((_) async => credit),
    build: build,
    act: (cubit) async {
      cubit
        ..nameChanged('Вклад')
        ..typeChanged(AccountType.savings)
        ..cardLast4Changed('4831')
        ..creditLimitChanged('1000')
        ..interestRateChanged('6,2');
      await cubit.save();
    },
    verify: (_) {
      final draft = capturedCreate();
      expect(draft.balance, 0);
      expect(draft.interestRate, 6.2);
      expect(draft.cardLast4, isNull);
      expect(draft.creditLimit, isNull);
    },
  );

  blocTest<AccountFormCubit, AccountFormState>(
    'минус в балансе — только у кредитной',
    build: build,
    act: (cubit) async {
      cubit
        ..nameChanged('Карта')
        ..balanceChanged('-100');
      await cubit.save();
    },
    skip: 2,
    expect: () => [
      isA<AccountFormState>().having((s) => s.fieldErrors, 'fieldErrors', {
        AccountField.balance: FieldError.invalidAmount,
      }),
    ],
  );

  blocTest<AccountFormCubit, AccountFormState>(
    'неполная маска карты и мусор в лимите — ошибки у полей',
    build: build,
    act: (cubit) async {
      cubit
        ..nameChanged('Кредитка')
        ..typeChanged(AccountType.credit)
        ..balanceChanged('-100')
        ..cardLast4Changed('12')
        ..creditLimitChanged('abc');
      await cubit.save();
    },
    skip: 5,
    expect: () => [
      isA<AccountFormState>().having((s) => s.fieldErrors, 'fieldErrors', {
        AccountField.cardLast4: FieldError.tooShort,
        AccountField.creditLimit: FieldError.invalidAmount,
      }),
    ],
  );

  blocTest<AccountFormCubit, AccountFormState>(
    'ошибка репозитория — failure, введённое сохранено',
    setUp: () =>
        when(() => repository.create(any())).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) async {
      cubit.nameChanged('Карта');
      await cubit.save();
    },
    skip: 2,
    expect: () => [
      const AccountFormState(
        name: 'Карта',
        status: .failure,
        failure: NetworkFailure(),
      ),
    ],
  );

  blocTest<AccountFormCubit, AccountFormState>(
    'отказ сервера по полю — ошибка у этого поля',
    setUp: () =>
        when(() => repository.create(any()))
            .thenThrow(const ValidationFailure('name', FieldError.required)),
    build: build,
    act: (cubit) async {
      cubit.nameChanged('Карта');
      await cubit.save();
    },
    skip: 2,
    expect: () => [
      const AccountFormState(
        name: 'Карта',
        status: .failure,
        fieldErrors: {AccountField.name: FieldError.required},
      ),
    ],
  );

  blocTest<AccountFormCubit, AccountFormState>(
    'init(id) заполняет поля текущим балансом',
    setUp: () =>
        when(() => repository.getAccount('credit'))
            .thenAnswer((_) async => credit),
    build: build,
    act: (cubit) => cubit.init('credit'),
    expect: () => [
      const AccountFormState(accountId: 'credit', isLoading: true),
      const AccountFormState(
        accountId: 'credit',
        name: 'Кредитка',
        type: AccountType.credit,
        balance: '-12400.50',
        color: EntityColor.red,
        cardLast4: '1234',
        creditLimit: '150000',
      ),
    ],
  );

  blocTest<AccountFormCubit, AccountFormState>(
    'init(id): счёта нет — failure, форма не показывается',
    setUp: () =>
        when(() => repository.getAccount('credit'))
            .thenThrow(const NotFoundFailure()),
    build: build,
    act: (cubit) => cubit.init('credit'),
    skip: 1,
    expect: () => [
      const AccountFormState(accountId: 'credit', failure: NotFoundFailure()),
    ],
  );

  blocTest<AccountFormCubit, AccountFormState>(
    'правка — update по id',
    setUp: () {
      when(() => repository.getAccount('credit'))
          .thenAnswer((_) async => credit);
      when(() => repository.update('credit', any()))
          .thenAnswer((_) async => credit);
    },
    build: build,
    act: (cubit) async {
      await cubit.init('credit');
      await cubit.save();
    },
    verify: (_) {
      final draft =
          verify(() => repository.update('credit', captureAny()))
                  .captured
                  .single
              as AccountDraft;
      expect(draft.balance, -1240050);
      expect(draft.creditLimit, 15000000);
      expect(draft.balanceChanged, isFalse, reason: 'баланс не трогали');
      verifyNever(() => repository.create(any()));
    },
  );

  test('правка баланса — balanceChanged', () async {
    when(() => repository.getAccount('credit')).thenAnswer((_) async => credit);
    when(() => repository.update('credit', any()))
        .thenAnswer((_) async => credit);
    final cubit = build();
    await cubit.init('credit');
    cubit.balanceChanged('-100');
    await cubit.save();

    final draft =
        verify(() => repository.update('credit', captureAny())).captured.single
            as AccountDraft;
    expect(draft.balanceChanged, isTrue);
    await cubit.close();
  });
}
