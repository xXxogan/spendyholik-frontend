import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/debts/data/models/debt_model.dart';
import 'package:spendyholik/features/debts/data/repositories/debt_repository.dart';
import 'package:spendyholik/features/debts/presentation/cubit/debt_repay_cubit.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

DebtModel debt({int remaining = 1200000}) => DebtModel(
  currency: Currency.rub,
  id: 'dmitry',
  counterparty: 'Дмитрий',
  direction: DebtDirection.iOwe,
  total: 1200000,
  remaining: remaining,
  createdAt: DateTime(2026, 10, 24),
);

void main() {
  late MockDebtRepository repository;

  setUp(() => repository = MockDebtRepository());

  DebtRepayCubit build() => DebtRepayCubit(repository);

  blocTest<DebtRepayCubit, DebtRepayState>(
    'init — сумма сразу на весь остаток',
    build: build,
    act: (cubit) => cubit.init(debt()),
    expect: () => [
      const DebtRepayState(
        debtId: 'dmitry',
        remaining: 1200000,
        amount: '12000',
      ),
    ],
  );

  blocTest<DebtRepayCubit, DebtRepayState>(
    'setHalf: 12 000 → 6 000',
    build: build,
    act: (cubit) => cubit
      ..init(debt())
      ..amountChanged('100')
      ..setHalf(),
    skip: 2,
    expect: () => [
      const DebtRepayState(
        debtId: 'dmitry',
        remaining: 1200000,
        amount: '6000',
      ),
    ],
  );

  blocTest<DebtRepayCubit, DebtRepayState>(
    'setHalf: нечётный остаток — вниз до целых рублей',
    build: build,
    act: (cubit) => cubit
      ..init(debt(remaining: 1200150))
      ..setHalf(),
    skip: 1,
    expect: () => [
      const DebtRepayState(
        debtId: 'dmitry',
        remaining: 1200150,
        amount: '6000',
      ),
    ],
  );

  blocTest<DebtRepayCubit, DebtRepayState>(
    'setFull после ручного ввода — снова весь остаток',
    build: build,
    act: (cubit) => cubit
      ..init(debt(remaining: 600000))
      ..amountChanged('100')
      ..setFull(),
    skip: 2,
    expect: () => [
      const DebtRepayState(debtId: 'dmitry', remaining: 600000, amount: '6000'),
    ],
  );

  blocTest<DebtRepayCubit, DebtRepayState>(
    'сумма 0 и без счёта — ошибки обоих полей, в репозиторий не идём',
    build: build,
    act: (cubit) => cubit
      ..init(debt())
      ..amountChanged('0')
      ..submit(),
    skip: 2,
    expect: () => [
      const DebtRepayState(
        debtId: 'dmitry',
        remaining: 1200000,
        amount: '0',
        fieldErrors: {
          RepayField.amount: FieldError.invalidAmount,
          RepayField.accountId: FieldError.required,
        },
      ),
    ],
    verify: (_) => verifyNever(() => repository.repay(any(), any(), any())),
  );

  blocTest<DebtRepayCubit, DebtRepayState>(
    'больше остатка — exceedsRemaining у суммы',
    setUp: () => when(
      () => repository.repay(any(), any(), any()),
    ).thenThrow(const ValidationFailure('amount', FieldError.exceedsRemaining)),
    build: build,
    act: (cubit) => cubit
      ..init(debt())
      ..amountChanged('13000')
      ..accountChanged('acc-tinkoff')
      ..submit(),
    skip: 4,
    expect: () => [
      const DebtRepayState(
        debtId: 'dmitry',
        remaining: 1200000,
        amount: '13000',
        accountId: 'acc-tinkoff',
        status: FormStatus.failure,
        fieldErrors: {RepayField.amount: FieldError.exceedsRemaining},
      ),
    ],
  );

  blocTest<DebtRepayCubit, DebtRepayState>(
    'успех: repay с суммой в копейках, затем success',
    setUp: () =>
        when(() => repository.repay(any(), any(), any()))
            .thenAnswer((_) async => debt(remaining: 600000)),
    build: build,
    act: (cubit) => cubit
      ..init(debt())
      ..setHalf()
      ..accountChanged('acc-tinkoff')
      ..submit(),
    skip: 4,
    expect: () => [
      isA<DebtRepayState>().having(
        (s) => s.status,
        'status',
        FormStatus.success,
      ),
    ],
    verify: (_) =>
        verify(() => repository.repay('dmitry', 600000, 'acc-tinkoff'))
            .called(1),
  );
}
