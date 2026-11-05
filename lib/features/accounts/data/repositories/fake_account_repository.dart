import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/account_repository.dart';
import 'package:spendyholik/features/transactions/transactions.dart';

@LazySingleton(as: AccountRepository)
class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository(this._backend, this._bus);

  final FakeBackend _backend;
  final DataChangeBus _bus;

  @override
  Future<List<AccountModel>> getAccounts() =>
      _backend(() => List.of(_backend.accounts));

  @override
  Future<AccountModel> getAccount(String id) => _backend(() => _find(id));

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
      _backend(() {
        final account = _find(id);
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day - weeks * 7);
        final changes =
            [
                  ..._backend.transactions
                      .where((t) => t.account.id == id || t.toAccount?.id == id)
                      .map((t) => t.occurredAt),
                  ..._backend.contributionMomentsOf(id),
                  ..._backend.debtRepaymentMomentsOf(id),
                ]
                .where(
                  (moment) => !moment.isBefore(start) && !moment.isAfter(now),
                )
                .toList()
              ..sort();

        return [
          BalancePoint(at: start, balance: _backend.balanceAt(id, start)),
          for (final moment in changes)
            BalancePoint(
              at: moment,
              balance: _backend.balanceAt(
                id,
                moment.add(const Duration(microseconds: 1)),
              ),
            ),
          BalancePoint(at: now, balance: account.balance),
        ];
      });

  @override
  Future<AccountModel> create(AccountDraft draft) async {
    final created = await _backend(() => _backend.addAccount(draft));
    _bus.emit({DataTopic.accounts});
    return created;
  }

  @override
  Future<AccountModel> update(String id, AccountDraft draft) async {
    final updated = await _backend(() {
      _find(id);
      _backend.updateAccount(id, draft);
      return _find(id);
    });
    // Имя счёта видно в операциях, истории целей и долгов, шаблонах.
    _bus.emit({
      DataTopic.accounts,
      DataTopic.transactions,
      DataTopic.goals,
      DataTopic.debts,
      DataTopic.recurring,
    });
    return updated;
  }

  @override
  Future<void> archive(String id) async {
    await _backend(() {
      _find(id);
      _backend.setAccountArchived(id, archived: true);
    });
    _bus.emit({DataTopic.accounts});
  }

  @override
  Future<void> unarchive(String id) async {
    await _backend(() {
      _find(id);
      _backend.setAccountArchived(id, archived: false);
    });
    _bus.emit({DataTopic.accounts});
  }

  AccountModel _find(String id) => _backend.accounts.firstWhere(
    (account) => account.id == id,
    orElse: () => throw const NotFoundFailure(),
  );
}
