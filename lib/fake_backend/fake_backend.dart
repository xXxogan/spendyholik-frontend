import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/config/app_config.dart';
import 'package:spendyholik/fake_backend/seed.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/categories/categories.dart';
import 'package:spendyholik/features/transactions/transactions.dart';

/// «Сервер» фазы 1: данные в памяти до перезапуска. В фазе 2 удаляется
/// вместе с фейковыми репозиториями.
@lazySingleton
class FakeBackend {
  FakeBackend() {
    _categories = FakeSeed.categories();
    transactions = FakeSeed.transactions(
      DateTime.now(),
      _initialAccounts,
      _categories,
    );
  }

  /// Начальные балансы; итоговые считаются из операций, как на сервере.
  final List<AccountModel> _initialAccounts = FakeSeed.initialAccounts();
  late final List<CategoryModel> _categories;
  late final List<TransactionModel> transactions;

  List<AccountModel> get accounts => [
    for (final a in _initialAccounts)
      a.copyWith(balance: a.balance + _delta(a.id)),
  ];

  List<CategoryModel> get categories => [
    for (final c in _categories)
      c.copyWith(
        transactionCount: transactions
            .where((t) => t.category?.id == c.id)
            .length,
      ),
  ];

  /// Баланс счёта на момент [moment]: операции раньше него, не включая.
  int balanceAt(String accountId, DateTime moment) {
    final initial = _initialAccounts
        .firstWhere((a) => a.id == accountId)
        .balance;
    return initial + _delta(accountId, before: moment);
  }

  void setAccountArchived(String accountId, {required bool archived}) {
    final index = _initialAccounts.indexWhere((a) => a.id == accountId);
    _initialAccounts[index] = _initialAccounts[index].copyWith(
      isArchived: archived,
    );
  }

  int _delta(String accountId, {DateTime? before}) {
    var delta = 0;
    for (final t in transactions) {
      if (before != null && !t.occurredAt.isBefore(before)) continue;
      switch (t.type) {
        case TransactionType.expense:
          if (t.account.id == accountId) delta -= t.amount;
        case TransactionType.income:
          if (t.account.id == accountId) delta += t.amount;
        case TransactionType.transfer:
          if (t.account.id == accountId) delta -= t.amount;
          if (t.toAccount?.id == accountId) delta += t.amount;
      }
    }
    return delta;
  }

  Future<T> call<T>(T Function() handler) async {
    await Future<void>.delayed(AppConfig.fakeLatency);
    return handler();
  }
}
