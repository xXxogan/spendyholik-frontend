import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/account_repository.dart';
import 'package:spendyholik/features/transactions/transactions.dart';

@LazySingleton(as: AccountRepository)
class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository(this._backend);

  final FakeBackend _backend;

  @override
  Future<List<AccountModel>> getAccounts() => _backend(() => List.of(_backend.accounts));

  @override
  Future<AccountModel> getAccount(String id) => throw UnimplementedError();

  @override
  Future<TotalBalance> getTotalBalance() => _backend(() {
    final month = DatePeriod.current(PeriodPreset.month, DateTime.now());
    var monthDelta = 0;
    for (final transaction in _backend.transactions) {
      if (!month.contains(transaction.occurredAt)) continue;
      monthDelta += switch (transaction.type) {
        TransactionType.income => transaction.amount,
        TransactionType.expense => -transaction.amount,
        TransactionType.transfer => 0,
      };
    }

    return TotalBalance(
      total: _backend.accounts
          .where((account) => !account.isArchived)
          .fold(0, (sum, account) => sum + account.balance),
      monthDelta: monthDelta,
    );
  });

  @override
  Future<List<BalancePoint>> getBalanceHistory(String id, {int weeks = 6}) =>
      throw UnimplementedError();

  @override
  Future<AccountModel> create(AccountDraft draft) => throw UnimplementedError();

  @override
  Future<AccountModel> update(String id, AccountDraft draft) => throw UnimplementedError();

  @override
  Future<void> archive(String id) => throw UnimplementedError();
}
