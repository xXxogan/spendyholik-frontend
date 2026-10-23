part of 'transaction_detail_cubit.dart';

@freezed
sealed class TransactionDetailState with _$TransactionDetailState {
  const factory TransactionDetailState.loading() = TransactionDetailLoading;
  const factory TransactionDetailState.loaded(TransactionModel transaction) =
      TransactionDetailLoaded;
  const factory TransactionDetailState.deleted() = TransactionDetailDeleted;
  const factory TransactionDetailState.error(Failure failure) =
      TransactionDetailError;
}
