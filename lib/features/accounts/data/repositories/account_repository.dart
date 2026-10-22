import 'package:spendyholik/features/accounts/data/models/models.dart';

/// Все методы бросают только [Failure] из `core/errors`.
abstract interface class AccountRepository {
  Future<List<AccountModel>> getAccounts();

  /// [NotFoundFailure], если счёта нет.
  Future<AccountModel> getAccount(String id);

  Future<TotalBalance> getTotalBalance();

  /// Начало периода, точка на каждое изменение баланса и сейчас — по возрастанию.
  Future<List<BalancePoint>> getBalanceHistory(String id, {int weeks = 6});

  Future<AccountModel> create(AccountDraft draft);

  Future<AccountModel> update(String id, AccountDraft draft);

  Future<void> archive(String id);

  Future<void> unarchive(String id);
}
