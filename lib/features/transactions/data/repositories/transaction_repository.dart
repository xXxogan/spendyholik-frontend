import 'package:spendyholik/features/transactions/data/models/models.dart';

/// Все методы бросают только [Failure] из `core/errors`.
abstract interface class TransactionRepository {
  /// Страница по убыванию [TransactionModel.occurredAt]; [cursor] — из
  /// [TransactionPage.nextCursor] предыдущей. Размер — [TransactionFilter.limit]
  /// или `AppConfig.transactionsPageSize`.
  Future<TransactionPage> getPage(TransactionFilter filter, {String? cursor});

  /// Первая страница целиком — там, где подгрузки нет.
  Future<List<TransactionModel>> getTransactions(TransactionFilter filter);

  /// [NotFoundFailure], если операции нет.
  Future<TransactionModel> getTransaction(String id);

  Future<TransactionModel> create(TransactionDraft draft);

  Future<TransactionModel> update(String id, TransactionDraft draft);

  Future<void> delete(String id);
}
