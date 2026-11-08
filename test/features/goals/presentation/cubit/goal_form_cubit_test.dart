import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/goals/data/models/goal_model.dart';
import 'package:spendyholik/features/goals/data/repositories/goal_repository.dart';
import 'package:spendyholik/features/goals/presentation/cubit/goal_form_cubit.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

void main() {
  late MockGoalRepository repository;

  final trip = GoalModel(
    currency: Currency.rub,
    id: 'trip',
    name: 'Отпуск',
    target: 9000000,
    saved: 4500000,
    deadline: DateTime(2027, 7),
  );

  setUpAll(
    () => registerFallbackValue(
      const GoalDraft(name: '', target: 0, initialContribution: 0),
    ),
  );

  setUp(() => repository = MockGoalRepository());

  GoalFormCubit build() => GoalFormCubit(repository);

  blocTest<GoalFormCubit, GoalFormState>(
    'правка: поля заполняются из цели',
    setUp: () =>
        when(() => repository.getGoal('trip')).thenAnswer((_) async => trip),
    build: build,
    act: (cubit) => cubit.init('trip'),
    expect: () => [
      const GoalFormState(goalId: 'trip', isLoading: true),
      GoalFormState(
        goalId: 'trip',
        name: 'Отпуск',
        target: '90000',
        deadline: DateTime(2027, 7),
      ),
    ],
  );

  blocTest<GoalFormCubit, GoalFormState>(
    'без имени — required',
    build: build,
    act: (cubit) => cubit
      ..targetChanged('100000')
      ..save(),
    skip: 1,
    expect: () => [
      const GoalFormState(
        target: '100000',
        fieldErrors: {GoalField.name: FieldError.required},
      ),
    ],
    verify: (_) => verifyNever(() => repository.create(any())),
  );

  blocTest<GoalFormCubit, GoalFormState>(
    'целевая сумма 0 — invalidAmount',
    build: build,
    act: (cubit) => cubit
      ..nameChanged('Отпуск')
      ..targetChanged('0')
      ..save(),
    skip: 2,
    expect: () => [
      const GoalFormState(
        name: 'Отпуск',
        target: '0',
        fieldErrors: {GoalField.target: FieldError.invalidAmount},
      ),
    ],
  );

  blocTest<GoalFormCubit, GoalFormState>(
    'взнос больше цели — exceedsTarget',
    build: build,
    act: (cubit) => cubit
      ..nameChanged('Отпуск')
      ..targetChanged('1000')
      ..initialContributionChanged('2000')
      ..initialAccountChanged('acc-savings')
      ..save(),
    skip: 4,
    expect: () => [
      const GoalFormState(
        name: 'Отпуск',
        target: '1000',
        initialContribution: '2000',
        initialAccountId: 'acc-savings',
        fieldErrors: {GoalField.initialContribution: FieldError.exceedsTarget},
      ),
    ],
  );

  blocTest<GoalFormCubit, GoalFormState>(
    'взнос без счёта — required у счёта',
    build: build,
    act: (cubit) => cubit
      ..nameChanged('Отпуск')
      ..targetChanged('1000')
      ..initialContributionChanged('500')
      ..save(),
    skip: 3,
    expect: () => [
      const GoalFormState(
        name: 'Отпуск',
        target: '1000',
        initialContribution: '500',
        fieldErrors: {GoalField.initialAccountId: FieldError.required},
      ),
    ],
  );

  blocTest<GoalFormCubit, GoalFormState>(
    'успех: create с черновиком; пустой взнос — 0 и без счёта',
    setUp: () =>
        when(() => repository.create(any())).thenAnswer((_) async => trip),
    build: build,
    act: (cubit) => cubit
      ..nameChanged(' Отпуск ')
      ..targetChanged('90 000')
      ..save(),
    skip: 3,
    expect: () => [
      isA<GoalFormState>().having(
        (s) => s.status,
        'status',
        FormStatus.success,
      ),
    ],
    verify: (_) {
      final draft =
          verify(() => repository.create(captureAny())).captured.single
              as GoalDraft;
      expect(draft.name, 'Отпуск');
      expect(draft.target, 9000000);
      expect(draft.initialContribution, 0);
      expect(draft.initialAccountId, isNull);
    },
  );

  blocTest<GoalFormCubit, GoalFormState>(
    'правка: update без взноса',
    setUp: () {
      when(() => repository.getGoal('trip')).thenAnswer((_) async => trip);
      when(() => repository.update(any(), any())).thenAnswer((_) async => trip);
    },
    build: build,
    act: (cubit) async {
      await cubit.init('trip');
      cubit.targetChanged('100000');
      await cubit.save();
    },
    verify: (_) {
      final draft =
          verify(() => repository.update('trip', captureAny())).captured.single
              as GoalDraft;
      expect(draft.target, 10000000);
      expect(draft.initialContribution, 0);
      expect(draft.deadline, DateTime(2027, 7));
    },
  );

  blocTest<GoalFormCubit, GoalFormState>(
    'удаление: submitting → deleted',
    setUp: () {
      when(() => repository.getGoal('trip')).thenAnswer((_) async => trip);
      when(() => repository.delete('trip')).thenAnswer((_) async {});
    },
    build: build,
    act: (cubit) async {
      await cubit.init('trip');
      await cubit.delete();
    },
    skip: 3,
    expect: () => [
      isA<GoalFormState>().having((s) => s.deleted, 'deleted', true),
    ],
  );

  blocTest<GoalFormCubit, GoalFormState>(
    'ошибка удаления — failure с ошибкой',
    setUp: () {
      when(() => repository.getGoal('trip')).thenAnswer((_) async => trip);
      when(() => repository.delete('trip')).thenThrow(const NetworkFailure());
    },
    build: build,
    act: (cubit) async {
      await cubit.init('trip');
      await cubit.delete();
    },
    skip: 3,
    expect: () => [
      isA<GoalFormState>()
          .having((s) => s.status, 'status', FormStatus.failure)
          .having((s) => s.failure, 'failure', const NetworkFailure())
          .having((s) => s.deleted, 'deleted', false),
    ],
  );
}
