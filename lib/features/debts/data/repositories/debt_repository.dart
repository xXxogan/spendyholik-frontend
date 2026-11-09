import 'package:spendyholik/features/debts/data/models/models.dart';

/// Все методы бросают только [Failure] из `core/errors`.
abstract interface class DebtRepository {
  /// Открытые, затем закрытые.
  Future<List<DebtModel>> getDebts();

  Future<DebtModel> getDebt(String id);

  /// Новые первыми.
  Future<List<DebtEvent>> getHistory(String id);

  Future<DebtModel> create(DebtDraft draft);

  Future<DebtModel> update(String id, DebtDraft draft);

  /// `ValidationFailure('amount', exceedsRemaining)`, если сумма больше остатка.
  /// Новый остаток экраны получают по шине — без перечитывания здесь.
  Future<void> repay(String id, int amount, String accountId);
}
