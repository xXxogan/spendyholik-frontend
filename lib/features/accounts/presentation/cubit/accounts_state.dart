part of 'accounts_cubit.dart';

@freezed
sealed class AccountsState with _$AccountsState {
  const factory AccountsState.loading() = AccountsLoading;
  const factory AccountsState.loaded(
    List<AccountModel> accounts,
    AccountsFilter filter,
  ) = AccountsLoaded;
  const factory AccountsState.empty(AccountsFilter filter) = AccountsEmpty;
  const factory AccountsState.error(Failure failure) = AccountsError;
}
