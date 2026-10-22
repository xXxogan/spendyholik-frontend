part of 'total_balance_cubit.dart';

@freezed
sealed class TotalBalanceState with _$TotalBalanceState {
  const factory TotalBalanceState.loading() = TotalBalanceLoading;
  const factory TotalBalanceState.loaded(TotalBalance balance) =
      TotalBalanceLoaded;
  const factory TotalBalanceState.error(Failure failure) = TotalBalanceError;
}
