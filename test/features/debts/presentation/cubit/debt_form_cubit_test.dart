import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/debts/data/models/debt_model.dart';
import 'package:spendyholik/features/debts/data/repositories/debt_repository.dart';
import 'package:spendyholik/features/debts/presentation/cubit/debt_form_cubit.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

void main() {
  late MockDebtRepository repository;

  final dmitry = DebtModel(
    id: 'dmitry',
    counterparty: 'Дмитрий',
    direction: DebtDirection.owedToMe,
    total: 1500000,
    remaining: 1000000,
    createdAt: DateTime(2026, 9),
  );

  setUpAll(
    () => registerFallbackValue(
      const DebtDraft(counterparty: '', direction: .iOwe, amount: 0),
    ),
  );

  setUp(() => repository = MockDebtRepository());

  DebtFormCubit build() => DebtFormCubit(repository);

  blocTest<DebtFormCubit, DebtFormState>(
    'без имени — required, пустая сумма — invalidAmount, репозиторий не вызван',
    build: build,
    act: (cubit) => cubit.save(),
    expect: () => [
      const DebtFormState(
        fieldErrors: {
          DebtField.counterparty: FieldError.required,
          DebtField.amount: FieldError.invalidAmount,
        },
      ),
    ],
    verify: (_) => verifyNever(() => repository.create(any())),
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'сумма 0 — invalidAmount',
    build: build,
    act: (cubit) => cubit
      ..counterpartyChanged('Анна')
      ..amountChanged('0')
      ..save(),
    skip: 2,
    expect: () => [
      const DebtFormState(
        counterparty: 'Анна',
        amount: '0',
        fieldErrors: {DebtField.amount: FieldError.invalidAmount},
      ),
    ],
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'start: направление задано',
    build: build,
    act: (cubit) => cubit.start(.owedToMe),
    expect: () => [const DebtFormState(direction: .owedToMe)],
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'правка: поля заполняются из долга',
    setUp: () =>
        when(() => repository.getDebt('dmitry'))
            .thenAnswer((_) async => dmitry),
    build: build,
    act: (cubit) => cubit.init('dmitry'),
    expect: () => [
      const DebtFormState(debtId: 'dmitry', isLoading: true),
      const DebtFormState(
        debtId: 'dmitry',
        counterparty: 'Дмитрий',
        direction: .owedToMe,
        amount: '15000',
      ),
    ],
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'правка: направление не меняется',
    setUp: () =>
        when(() => repository.getDebt('dmitry'))
            .thenAnswer((_) async => dmitry),
    build: build,
    act: (cubit) async {
      await cubit.init('dmitry');
      cubit.directionChanged(.iOwe);
    },
    skip: 2,
    expect: () => const <DebtFormState>[],
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'сумма меньше погашенного — ошибка у amount',
    setUp: () => when(() => repository.update('dmitry', any()))
        .thenThrow(const ValidationFailure('amount', FieldError.belowRepaid)),
    build: build,
    seed: () => const DebtFormState(
      debtId: 'dmitry',
      counterparty: 'Дмитрий',
      amount: '10',
    ),
    act: (cubit) => cubit.save(),
    expect: () => [
      const DebtFormState(
        debtId: 'dmitry',
        counterparty: 'Дмитрий',
        amount: '10',
        status: .submitting,
      ),
      const DebtFormState(
        debtId: 'dmitry',
        counterparty: 'Дмитрий',
        amount: '10',
        status: .failure,
        fieldErrors: {DebtField.amount: FieldError.belowRepaid},
      ),
    ],
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'success create: имя обрезано, сумма в копейках, пустая заметка — null',
    setUp: () =>
        when(() => repository.create(any())).thenAnswer((_) async => dmitry),
    build: build,
    act: (cubit) => cubit
      ..counterpartyChanged('  Анна ')
      ..amountChanged('1500,50')
      ..noteChanged('')
      ..save(),
    // noteChanged('') состояние не меняет, поэтому пропускаем два emit.
    skip: 2,
    expect: () => [
      isA<DebtFormState>().having(
        (s) => s.status,
        'status',
        FormStatus.submitting,
      ),
      isA<DebtFormState>().having(
        (s) => s.status,
        'status',
        FormStatus.success,
      ),
    ],
    verify: (_) {
      final draft =
          verify(() => repository.create(captureAny())).captured.single
              as DebtDraft;
      expect(draft.counterparty, 'Анна');
      expect(draft.amount, 150050);
      expect(draft.note, isNull);
      expect(draft.direction, DebtDirection.iOwe);
    },
  );
}
