import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/config/app_config.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/date_period.dart';
import 'package:spendyholik/fake_backend/seed.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/features/categories/categories.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';
import 'package:spendyholik/features/goals/data/models/models.dart';
import 'package:spendyholik/features/recurring/data/models/models.dart';
import 'package:spendyholik/features/transactions/transactions.dart';

/// «Сервер» фазы 1: данные в памяти до перезапуска. В фазе 2 удаляется
/// вместе с фейковыми репозиториями.
@lazySingleton
class FakeBackend {
  FakeBackend() {
    _categories = List.of(FakeSeed.categories());
    transactions = List.of(
      FakeSeed.transactions(DateTime.now(), _initialAccounts, _categories),
    );
    _budgets = FakeSeed.budgets(DateTime.now(), _spent);
    _goals = FakeSeed.goals(DateTime.now());
    _contributions = FakeSeed.contributions(DateTime.now(), _initialAccounts);
    _recurring = FakeSeed.recurring(DateTime.now());
    _debts = FakeSeed.debts(DateTime.now());
    _debtEvents = FakeSeed.debtEvents(DateTime.now(), _debts, _initialAccounts);
  }

  /// Начальные балансы; итоговые считаются из операций, как на сервере.
  /// Копии: сид отдаёт const-списки, а «сервер» их меняет.
  final List<AccountModel> _initialAccounts = List.of(
    FakeSeed.initialAccounts(),
  );
  late final List<CategoryModel> _categories;
  late final List<TransactionModel> transactions;
  late final List<(String, BudgetDraft)> _budgets;
  late final List<GoalModel> _goals;
  late final List<(String, GoalContribution)> _contributions;
  late final List<(String, RecurringDraft, bool)> _recurring;
  late final List<DebtModel> _debts;
  late final List<(String, DebtEvent)> _debtEvents;

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

  List<BudgetModel> get budgets {
    final now = DateTime.now();
    return [
      for (final (id, draft) in _budgets)
        () {
          final period = _budgetPeriod(draft, now);
          return BudgetModel(
            id: id,
            category: _categories
                .firstWhere((c) => c.id == draft.categoryId)
                .toRef(),
            limit: draft.limit,
            spent: _spent(draft.categoryId, period),
            period: draft.period,
            currentPeriod: period,
          );
        }(),
    ];
  }

  List<GoalModel> get goals => [
    for (final goal in _goals)
      goal.copyWith(
        saved: _contributions
            .where((c) => c.$1 == goal.id)
            .fold<int>(0, (sum, c) => sum + c.$2.amount),
      ),
  ];

  GoalContribution addContribution(
    String goalId,
    int amount,
    AccountModel from,
  ) {
    final contribution = GoalContribution(
      id: 'gc-${DateTime.now().microsecondsSinceEpoch}',
      amount: amount,
      from: AccountRef(id: from.id, name: from.name, color: from.color),
      date: DateTime.now(),
    );
    _contributions.add((goalId, contribution));
    return contribution;
  }

  /// `remaining` = сумма долга минус погашения.
  List<DebtModel> get debts => [
    for (final d in _debts)
      DebtModel(
        id: d.id,
        counterparty: d.counterparty,
        direction: d.direction,
        total: d.total,
        remaining:
            d.total -
            _debtEvents
                .where((e) => e.$1 == d.id && e.$2.kind == .repayment)
                .fold<int>(0, (sum, e) => sum + e.$2.amount),
        dueDate: d.dueDate,
        note: d.note,
        createdAt: d.createdAt,
      ),
  ];

  void addDebtRepayment(String debtId, int amount, AccountModel account) =>
      _debtEvents.add((
        debtId,
        DebtEvent(
          id: 'de-${DateTime.now().microsecondsSinceEpoch}',
          kind: DebtEventKind.repayment,
          amount: amount,
          date: DateTime.now(),
          account: AccountRef(
            id: account.id,
            name: account.name,
            color: account.color,
          ),
        ),
      ));

  List<DebtEvent> debtEventsOf(String debtId) => [
    for (final (id, event) in _debtEvents)
      if (id == debtId) event,
  ]..sort((a, b) => b.date.compareTo(a.date));

  /// Моменты погашений долгов через этот счёт — точки истории баланса.
  List<DateTime> debtRepaymentMomentsOf(String accountId) => [
    for (final (_, e) in _debtEvents)
      if (e.kind == .repayment && e.account?.id == accountId) e.date,
  ];

  List<RecurringModel> get recurring {
    final now = DateTime.now();
    return [
      for (final (id, draft, paused) in _recurring)
        RecurringModel(
          id: id,
          title: draft.title,
          type: draft.type,
          amount: draft.amount,
          category: _categories
              .firstWhere((c) => c.id == draft.categoryId)
              .toRef(),
          account: () {
            final a = _initialAccounts.firstWhere(
              (a) => a.id == draft.accountId,
            );
            return AccountRef(id: a.id, name: a.name, color: a.color);
          }(),
          frequency: draft.frequency,
          anchor: draft.anchor,
          nextDate: draft.frequency.nextAfter(draft.anchor, now),
          isPaused: paused,
        ),
    ];
  }

  void setRecurringPaused(String id, {required bool paused}) {
    final index = _recurring.indexWhere((r) => r.$1 == id);
    if (index == -1) throw const NotFoundFailure();
    _recurring[index] = (id, _recurring[index].$2, paused);
  }

  String addRecurring(RecurringDraft draft) {
    final id = 'rec-${DateTime.now().microsecondsSinceEpoch}';
    _recurring.add((id, draft, false));
    return id;
  }

  void updateRecurring(String id, RecurringDraft draft) {
    final index = _recurring.indexWhere((r) => r.$1 == id);
    if (index == -1) throw const NotFoundFailure();
    // Пауза — свойство шаблона, правка полей её не снимает.
    _recurring[index] = (id, draft, _recurring[index].$3);
  }

  GoalModel addGoal(GoalDraft draft) {
    final goal = GoalModel(
      id: 'goal-${DateTime.now().microsecondsSinceEpoch}',
      name: draft.name,
      target: draft.target,
      saved: 0,
      deadline: draft.deadline,
    );
    _goals.add(goal);
    return goal;
  }

  void updateGoal(String goalId, GoalDraft draft) {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) throw const NotFoundFailure();
    _goals[index] = GoalModel(
      id: goalId,
      name: draft.name,
      target: draft.target,
      saved: 0,
      deadline: draft.deadline,
    );
  }

  void deleteGoal(String goalId) {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) throw const NotFoundFailure();
    _goals.removeAt(index);
    _contributions.removeWhere((c) => c.$1 == goalId);
  }

  /// Моменты пополнений целей с этого счёта — точки истории баланса.
  List<DateTime> contributionMomentsOf(String accountId) => [
    for (final (_, c) in _contributions)
      if (c.from.id == accountId) c.date,
  ];

  List<GoalContribution> contributionsOf(String goalId) => [
    for (final (id, contribution) in _contributions)
      if (id == goalId) contribution,
  ]..sort((a, b) => b.date.compareTo(a.date));

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

  AccountModel addAccount(AccountDraft draft) {
    final account = AccountModel(
      id: 'acc-${DateTime.now().microsecondsSinceEpoch}',
      name: draft.name,
      type: draft.type,
      balance: draft.balance,
      color: draft.color,
      isArchived: false,
      cardLast4: draft.cardLast4,
      interestRate: draft.interestRate,
      creditLimit: draft.creditLimit,
    );
    _initialAccounts.add(account);
    return account;
  }

  /// [AccountDraft.balance] — желаемый текущий баланс: начальный сдвигается
  /// на разницу, операции остаются как есть.
  void updateAccount(String accountId, AccountDraft draft) {
    final index = _initialAccounts.indexWhere((a) => a.id == accountId);
    _initialAccounts[index] = AccountModel(
      id: accountId,
      name: draft.name,
      type: draft.type,
      balance: draft.balance - _delta(accountId),
      color: draft.color,
      isArchived: _initialAccounts[index].isArchived,
      cardLast4: draft.cardLast4,
      interestRate: draft.interestRate,
      creditLimit: draft.creditLimit,
    );
  }

  CategoryModel addCategory(CategoryDraft draft) {
    final category = CategoryModel(
      id: 'cat-${DateTime.now().microsecondsSinceEpoch}',
      name: draft.name,
      kind: draft.kind,
      icon: draft.icon,
      color: draft.color,
      parentId: draft.parentId,
      transactionCount: 0,
    );
    _categories.add(category);
    return category;
  }

  void updateCategory(String categoryId, CategoryDraft draft) {
    final index = _categories.indexWhere((c) => c.id == categoryId);
    _categories[index] = CategoryModel(
      id: categoryId,
      name: draft.name,
      kind: draft.kind,
      icon: draft.icon,
      color: draft.color,
      parentId: draft.parentId,
      transactionCount: 0,
    );
  }

  String addBudget(BudgetDraft draft) {
    final id = 'bud-${DateTime.now().microsecondsSinceEpoch}';
    _budgets.add((id, draft));
    return id;
  }

  void updateBudget(String budgetId, BudgetDraft draft) {
    final index = _budgets.indexWhere((b) => b.$1 == budgetId);
    if (index == -1) throw const NotFoundFailure();
    _budgets[index] = (budgetId, draft);
  }

  void deleteBudget(String budgetId) {
    final index = _budgets.indexWhere((b) => b.$1 == budgetId);
    if (index == -1) throw const NotFoundFailure();
    _budgets.removeAt(index);
  }

  void addTransaction(TransactionModel transaction) =>
      transactions.add(transaction);

  void replaceTransaction(TransactionModel transaction) {
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index == -1) throw const NotFoundFailure();
    transactions[index] = transaction;
  }

  void deleteTransaction(String id) {
    final index = transactions.indexWhere((t) => t.id == id);
    if (index == -1) throw const NotFoundFailure();
    transactions.removeAt(index);
  }

  DatePeriod _budgetPeriod(BudgetDraft draft, DateTime now) =>
      switch (draft.period) {
        BudgetPeriod.monthly => DatePeriod.current(PeriodPreset.month, now),
        BudgetPeriod.weekly => DatePeriod.current(PeriodPreset.week, now),
        BudgetPeriod.once => DatePeriod(
          start: draft.onceStart!,
          end: draft.onceEnd!,
        ),
      };

  /// Расходы категории вместе с её подкатегориями.
  int _spent(String categoryId, DatePeriod period) {
    final ids = {
      categoryId,
      for (final c in _categories)
        if (c.parentId == categoryId) c.id,
    };
    return transactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              ids.contains(t.category?.id) &&
              period.contains(t.occurredAt),
        )
        .fold(0, (sum, t) => sum + t.amount);
  }

  /// Пополнения целей и погашения долгов двигают счёт, хотя операциями не являются.
  int _delta(String accountId, {DateTime? before}) {
    var delta = 0;
    for (final (_, c) in _contributions) {
      if (before != null && !c.date.isBefore(before)) continue;
      if (c.from.id == accountId) delta -= c.amount;
    }
    for (final (debtId, e) in _debtEvents) {
      if (e.kind != .repayment || e.account?.id != accountId) continue;
      if (before != null && !e.date.isBefore(before)) continue;
      final direction = _debts.firstWhere((d) => d.id == debtId).direction;
      delta += direction == .iOwe ? -e.amount : e.amount;
    }
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
