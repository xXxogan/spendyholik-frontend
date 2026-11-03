part of 'debts_cubit.dart';

@freezed
sealed class DebtsState with _$DebtsState {
  const factory DebtsState.loading() = DebtsLoading;
  const factory DebtsState.loaded(
    List<DebtModel> visible,
    DebtDirection direction,
  ) = DebtsLoaded;
  const factory DebtsState.empty(DebtDirection direction) = DebtsEmpty;
  const factory DebtsState.error(Failure failure) = DebtsError;
}
