part of 'transactions_cubit.dart';

@freezed
sealed class TransactionsState with _$TransactionsState {
  const factory TransactionsState.loading() = TransactionsLoading;

  /// Дни по убыванию, внутри дня — по убыванию времени. [nextCursor] null —
  /// загружено всё; [loadingMore] — строка-скелетон внизу; [moreFailure] —
  /// внизу «Повторить», загруженное остаётся.
  const factory TransactionsState.loaded(
    List<TransactionDayGroup> groups,
    TransactionFilter filter, {
    String? nextCursor,
    @Default(false) bool loadingMore,
    Failure? moreFailure,
  }) = TransactionsLoaded;
  const factory TransactionsState.empty(TransactionFilter filter) =
      TransactionsEmpty;
  const factory TransactionsState.error(Failure failure) = TransactionsError;
}
