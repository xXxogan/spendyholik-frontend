import 'package:spendyholik/features/transactions/data/models/models.dart';

/// Все методы бросают только [Failure] из `core/errors`.
abstract interface class TransactionRepository {
  /// По убыванию [TransactionModel.occurredAt].
  Future<List<TransactionModel>> getTransactions(TransactionFilter filter);

  /// [NotFoundFailure], если операции нет.
  Future<TransactionModel> getTransaction(String id);

  Future<TransactionModel> create(TransactionDraft draft);

  Future<TransactionModel> update(String id, TransactionDraft draft);

  Future<void> delete(String id);
}
