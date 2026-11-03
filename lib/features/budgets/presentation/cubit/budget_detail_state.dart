part of 'budget_detail_cubit.dart';

@freezed
sealed class BudgetDetailState with _$BudgetDetailState {
  const factory BudgetDetailState.loading() = BudgetDetailLoading;
  const factory BudgetDetailState.loaded(BudgetModel budget) =
      BudgetDetailLoaded;
  const factory BudgetDetailState.error(Failure failure) = BudgetDetailError;
}
