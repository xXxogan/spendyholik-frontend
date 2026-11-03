import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/goals/data/models/goal_model.dart';
import 'package:spendyholik/features/goals/data/repositories/goal_repository.dart';
import 'package:spendyholik/features/goals/presentation/cubit/goal_top_up_cubit.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

void main() {
  late MockGoalRepository repository;

  setUp(() => repository = MockGoalRepository());

  GoalTopUpCubit build() => GoalTopUpCubit(repository);

  blocTest<GoalTopUpCubit, GoalTopUpState>(
    'сумма 0 — invalidAmount, в репозиторий не идём',
    build: build,
    act: (cubit) => cubit
      ..init('buffer')
      ..amountChanged('0')
      ..accountChanged('acc-savings')
      ..submit(),
    skip: 3,
    expect: () => [
      const GoalTopUpState(
        goalId: 'buffer',
        amount: '0',
        accountId: 'acc-savings',
        fieldErrors: {TopUpField.amount: FieldError.invalidAmount},
      ),
    ],
    verify: (_) =>
        verifyNever(() => repository.contribute(any(), any(), any())),
  );

  blocTest<GoalTopUpCubit, GoalTopUpState>(
    'без счёта — required у счёта',
    build: build,
    act: (cubit) => cubit
      ..init('buffer')
      ..amountChanged('20000')
      ..submit(),
    skip: 2,
    expect: () => [
      const GoalTopUpState(
        goalId: 'buffer',
        amount: '20000',
        fieldErrors: {TopUpField.accountId: FieldError.required},
      ),
    ],
  );

  blocTest<GoalTopUpCubit, GoalTopUpState>(
    'больше, чем на счёте — exceedsBalance у суммы',
    setUp: () => when(
      () => repository.contribute(any(), any(), any()),
    ).thenThrow(const ValidationFailure('amount', FieldError.exceedsBalance)),
    build: build,
    act: (cubit) => cubit
      ..init('buffer')
      ..amountChanged('20000')
      ..accountChanged('acc-cash')
      ..submit(),
    skip: 4,
    expect: () => [
      const GoalTopUpState(
        goalId: 'buffer',
        amount: '20000',
        accountId: 'acc-cash',
        status: FormStatus.failure,
        fieldErrors: {TopUpField.amount: FieldError.exceedsBalance},
      ),
    ],
  );

  blocTest<GoalTopUpCubit, GoalTopUpState>(
    'успех: contribute с суммой в копейках, затем success',
    setUp: () => when(() => repository.contribute(any(), any(), any()))
        .thenAnswer(
          (_) async => const GoalModel(
            id: 'buffer',
            name: 'Подушка',
            target: 20000000,
            saved: 14000000,
          ),
        ),
    build: build,
    act: (cubit) => cubit
      ..init('buffer')
      ..amountChanged('20 000')
      ..accountChanged('acc-savings')
      ..submit(),
    skip: 4,
    expect: () => [
      isA<GoalTopUpState>().having(
        (s) => s.status,
        'status',
        FormStatus.success,
      ),
    ],
    verify: (_) =>
        verify(() => repository.contribute('buffer', 2000000, 'acc-savings'))
            .called(1),
  );
}
