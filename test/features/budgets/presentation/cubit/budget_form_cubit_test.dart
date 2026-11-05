import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/budgets/data/models/budget_model.dart';
import 'package:spendyholik/features/budgets/data/repositories/budget_repository.dart';
import 'package:spendyholik/features/budgets/presentation/cubit/budget_form_cubit.dart';
import 'package:spendyholik/features/categories/categories.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late MockBudgetRepository repository;

  final existing = BudgetModel(
    id: 'b1',
    category: const CategoryRef(
      id: 'cat-food',
      name: 'Продукты',
      icon: EntityIcon.cart,
      color: EntityColor.green,
    ),
    limit: 2000000,
    spent: 0,
    period: BudgetPeriod.weekly,
    currentPeriod: DatePeriod(
      start: DateTime(2026, 11, 2),
      end: DateTime(2026, 11, 9),
    ),
  );

  setUpAll(
    () => registerFallbackValue(
      const BudgetDraft(categoryId: '', limit: 0, period: BudgetPeriod.monthly),
    ),
  );

  setUp(() => repository = MockBudgetRepository());

  BudgetFormCubit build() => BudgetFormCubit(repository);

  blocTest<BudgetFormCubit, BudgetFormState>(
    'правка: поля заполняются из бюджета',
    setUp: () =>
        when(() => repository.getBudget('b1'))
            .thenAnswer((_) async => existing),
    build: build,
    act: (cubit) => cubit.init('b1'),
    expect: () => [
      const BudgetFormState(budgetId: 'b1', isLoading: true),
      const BudgetFormState(
        budgetId: 'b1',
        categoryId: 'cat-food',
        limit: '20000',
        period: BudgetPeriod.weekly,
      ),
    ],
  );

  blocTest<BudgetFormCubit, BudgetFormState>(
    'лимит 0 — invalidAmount, в репозиторий не идём',
    build: build,
    act: (cubit) => cubit
      ..categoryChanged('cat-food')
      ..limitChanged('0')
      ..save(),
    skip: 2,
    expect: () => [
      const BudgetFormState(
        categoryId: 'cat-food',
        limit: '0',
        fieldErrors: {BudgetField.limit: FieldError.invalidAmount},
      ),
    ],
    verify: (_) => verifyNever(() => repository.create(any())),
  );

  blocTest<BudgetFormCubit, BudgetFormState>(
    'без категории — required',
    build: build,
    act: (cubit) => cubit
      ..limitChanged('5000')
      ..save(),
    skip: 1,
    expect: () => [
      const BudgetFormState(
        limit: '5000',
        fieldErrors: {BudgetField.categoryId: FieldError.required},
      ),
    ],
  );

  blocTest<BudgetFormCubit, BudgetFormState>(
    'разовый без дат — required у периода',
    build: build,
    act: (cubit) => cubit
      ..categoryChanged('cat-food')
      ..limitChanged('5000')
      ..periodChanged(BudgetPeriod.once)
      ..save(),
    skip: 3,
    expect: () => [
      const BudgetFormState(
        categoryId: 'cat-food',
        limit: '5000',
        period: BudgetPeriod.once,
        fieldErrors: {BudgetField.period: FieldError.required},
      ),
    ],
  );

  blocTest<BudgetFormCubit, BudgetFormState>(
    'на категорию уже есть бюджет — ошибка у поля категории',
    setUp: () => when(() => repository.create(any())).thenThrow(
      const ValidationFailure('categoryId', FieldError.alreadyExists),
    ),
    build: build,
    act: (cubit) => cubit
      ..categoryChanged('cat-food')
      ..limitChanged('5000')
      ..save(),
    skip: 3,
    expect: () => [
      const BudgetFormState(
        categoryId: 'cat-food',
        limit: '5000',
        status: FormStatus.failure,
        fieldErrors: {BudgetField.categoryId: FieldError.alreadyExists},
      ),
    ],
  );

  blocTest<BudgetFormCubit, BudgetFormState>(
    'успех: create с черновиком, затем success',
    setUp: () =>
        when(() => repository.create(any())).thenAnswer((_) async => existing),
    build: build,
    act: (cubit) => cubit
      ..categoryChanged('cat-food')
      ..limitChanged('20 000')
      ..save(),
    skip: 2,
    expect: () => [
      const BudgetFormState(
        categoryId: 'cat-food',
        limit: '20 000',
        status: FormStatus.submitting,
      ),
      const BudgetFormState(
        categoryId: 'cat-food',
        limit: '20 000',
        status: FormStatus.success,
      ),
    ],
    verify: (_) {
      final draft =
          verify(() => repository.create(captureAny())).captured.single
              as BudgetDraft;
      expect(draft.categoryId, 'cat-food');
      expect(draft.limit, 2000000);
      expect(draft.period, BudgetPeriod.monthly);
    },
  );

  blocTest<BudgetFormCubit, BudgetFormState>(
    'удаление: submitting → deleted',
    setUp: () {
      when(() => repository.getBudget('b1')).thenAnswer((_) async => existing);
      when(() => repository.delete('b1')).thenAnswer((_) async {});
    },
    build: build,
    act: (cubit) async {
      await cubit.init('b1');
      await cubit.delete();
    },
    skip: 2,
    expect: () => [
      isA<BudgetFormState>().having(
        (s) => s.status,
        'status',
        FormStatus.submitting,
      ),
      isA<BudgetFormState>().having((s) => s.deleted, 'deleted', true),
    ],
    verify: (_) => verify(() => repository.delete('b1')).called(1),
  );

  blocTest<BudgetFormCubit, BudgetFormState>(
    'ошибка удаления — failure с ошибкой, форма остаётся',
    setUp: () {
      when(() => repository.getBudget('b1')).thenAnswer((_) async => existing);
      when(() => repository.delete('b1')).thenThrow(const NetworkFailure());
    },
    build: build,
    act: (cubit) async {
      await cubit.init('b1');
      await cubit.delete();
    },
    skip: 3,
    expect: () => [
      const BudgetFormState(
        budgetId: 'b1',
        categoryId: 'cat-food',
        limit: '20000',
        period: BudgetPeriod.weekly,
        status: FormStatus.failure,
        failure: NetworkFailure(),
      ),
    ],
  );

  blocTest<BudgetFormCubit, BudgetFormState>(
    'неизвестное поле от сервера — общая ошибка, а не вечный спиннер',
    setUp: () => when(() => repository.create(any()))
        .thenThrow(const ValidationFailure('periodStart', FieldError.required)),
    build: build,
    act: (cubit) => cubit
      ..categoryChanged('cat-food')
      ..limitChanged('5000')
      ..save(),
    skip: 3,
    expect: () => [
      isA<BudgetFormState>()
          .having((s) => s.status, 'status', FormStatus.failure)
          .having((s) => s.failure, 'failure', isA<ValidationFailure>())
          .having((s) => s.fieldErrors, 'errors', isEmpty),
    ],
  );
}
