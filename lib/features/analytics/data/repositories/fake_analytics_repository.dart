import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/analytics/data/models/models.dart';
import 'package:spendyholik/features/analytics/data/repositories/analytics_repository.dart';
import 'package:spendyholik/features/transactions/transactions.dart';

@LazySingleton(as: AnalyticsRepository)
class FakeAnalyticsRepository implements AnalyticsRepository {
  FakeAnalyticsRepository(this._backend);

  final FakeBackend _backend;

  @override
  Future<AnalyticsReport> getReport(PeriodPreset preset, {DateTime? anchor}) =>
      _backend(() {
        final period = DatePeriod.current(preset, anchor ?? DateTime.now());
        final current = _totals(period);
        final previous = _totals(period.previous());

        final parentOf = {
          for (final c in _backend.categories) c.id: c.parentId ?? c.id,
        };
        final categories = {for (final c in _backend.categories) c.id: c};
        final byCategory = <String, int>{};
        for (final t in _inPeriod(period)) {
          if (t.type != TransactionType.expense) continue;
          final id = parentOf[t.category?.id];
          if (id == null) continue;
          byCategory[id] = (byCategory[id] ?? 0) + t.amount;
        }
        final shares = [
          for (final MapEntry(key: id, value: amount) in byCategory.entries)
            CategoryShare(
              category: categories[id]!.toRef(),
              amount: amount,
              share: amount / current.expense,
            ),
        ]..sort((a, b) => b.amount.compareTo(a.amount));

        final lastMonth = DateTime(period.start.year, period.start.month);
        final monthly = [
          for (var back = 5; back >= 0; back--)
            () {
              final month = DateTime(lastMonth.year, lastMonth.month - back);
              final totals = _totals(
                DatePeriod(
                  start: month,
                  end: DateTime(month.year, month.month + 1),
                ),
              );
              return MonthlyTotals(
                month: month,
                income: totals.income,
                expense: totals.expense,
              );
            }(),
        ];

        return AnalyticsReport(
          period: period,
          income: current.income,
          expense: current.expense,
          expenseChange: previous.expense == 0
              ? null
              : (current.expense - previous.expense) / previous.expense,
          expenseByCategory: shares,
          monthly: monthly,
        );
      });

  Iterable<TransactionModel> _inPeriod(DatePeriod period) =>
      _backend.transactions.where((t) => period.contains(t.occurredAt));

  ({int income, int expense}) _totals(DatePeriod period) {
    var income = 0;
    var expense = 0;
    for (final t in _inPeriod(period)) {
      switch (t.type) {
        case TransactionType.income:
          income += t.amount;
        case TransactionType.expense:
          expense += t.amount;
        case TransactionType.transfer:
          break;
      }
    }
    return (income: income, expense: expense);
  }
}
