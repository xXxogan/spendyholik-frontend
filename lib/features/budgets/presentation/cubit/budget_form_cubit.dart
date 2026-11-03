import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/features/budgets/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'budget_form_cubit.freezed.dart';
part 'budget_form_state.dart';

@injectable
class BudgetFormCubit extends Cubit<BudgetFormState>
    with CubitLogging<BudgetFormState> {
  BudgetFormCubit(this._repository) : super(const BudgetFormState());

  final BudgetRepository _repository;

  Future<void> init(String budgetId) async {
    emit(BudgetFormState(budgetId: budgetId, isLoading: true));
    try {
      final budget = await _repository.getBudget(budgetId);
      final once = budget.period == BudgetPeriod.once;
      emit(
        BudgetFormState(
          budgetId: budgetId,
          categoryId: budget.category.id,
          limit: formatAmountInput(budget.limit),
          period: budget.period,
          onceStart: once ? budget.currentPeriod.start : null,
          onceEnd: once ? budget.currentPeriod.end : null,
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(BudgetFormState(budgetId: budgetId, failure: failure));
    }
  }

  void categoryChanged(String value) => emit(
    state.copyWith(categoryId: value, fieldErrors: _without(.categoryId)),
  );

  void limitChanged(String value) =>
      emit(state.copyWith(limit: value, fieldErrors: _without(.limit)));

  void periodChanged(BudgetPeriod value) =>
      emit(state.copyWith(period: value, fieldErrors: _without(.period)));

  void onceRangeChanged(DateTime start, DateTime end) => emit(
    state.copyWith(
      onceStart: start,
      onceEnd: end,
      fieldErrors: _without(.period),
    ),
  );

  Future<void> save() async {
    final errors = <BudgetField, FieldError>{};
    final categoryId = state.categoryId;
    if (categoryId == null) errors[.categoryId] = .required;
    final limit = parseAmountInput(state.limit);
    if (limit == null) errors[.limit] = .invalidAmount;
    final once = state.period == BudgetPeriod.once;
    if (once && (state.onceStart == null || state.onceEnd == null)) {
      errors[.period] = .required;
    }
    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }

    final draft = BudgetDraft(
      categoryId: categoryId!,
      limit: limit!,
      period: state.period,
      onceStart: once ? state.onceStart : null,
      onceEnd: once ? state.onceEnd : null,
    );
    emit(state.copyWith(status: .submitting, failure: null));
    try {
      final budgetId = state.budgetId;
      if (budgetId == null) {
        await _repository.create(draft);
      } else {
        await _repository.update(budgetId, draft);
      }
      emit(state.copyWith(status: .success));
    } on ValidationFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(
        state.copyWith(
          status: .failure,
          fieldErrors: {
            BudgetField.values.byName(failure.field): failure.reason,
          },
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  Future<void> delete() async {
    emit(state.copyWith(status: .submitting, failure: null));
    try {
      await _repository.delete(state.budgetId!);
      emit(state.copyWith(deleted: true));
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  Map<BudgetField, FieldError> _without(BudgetField field) =>
      Map.of(state.fieldErrors)..remove(field);
}
