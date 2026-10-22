part of 'transactions_cubit.dart';

@freezed
sealed class TransactionsState with _$TransactionsState {
  const factory TransactionsState.loading() = TransactionsLoading;

  /// Дни по убыванию, внутри дня — по убыванию времени.
  const factory TransactionsState.loaded(
    List<TransactionDayGroup> groups,
    TransactionFilter filter,
  ) = TransactionsLoaded;
  const factory TransactionsState.empty(TransactionFilter filter) =
      TransactionsEmpty;
  const factory TransactionsState.error(Failure failure) = TransactionsError;
}
