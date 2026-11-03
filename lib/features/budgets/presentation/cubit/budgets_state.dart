part of 'budgets_cubit.dart';

@freezed
sealed class BudgetsState with _$BudgetsState {
  const factory BudgetsState.loading() = BudgetsLoading;
  const factory BudgetsState.loaded(List<BudgetModel> budgets) = BudgetsLoaded;
  const factory BudgetsState.empty() = BudgetsEmpty;
  const factory BudgetsState.error(Failure failure) = BudgetsError;
}
