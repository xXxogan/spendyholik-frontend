part of 'account_detail_cubit.dart';

@freezed
sealed class AccountDetailState with _$AccountDetailState {
  const factory AccountDetailState.loading() = AccountDetailLoading;
  const factory AccountDetailState.loaded(
    AccountModel account,
    List<BalancePoint> history,
  ) = AccountDetailLoaded;
  const factory AccountDetailState.archived() = AccountDetailArchived;
  const factory AccountDetailState.error(Failure failure) = AccountDetailError;
}
