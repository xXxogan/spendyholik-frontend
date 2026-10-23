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

        final trend = [
          for (final bucket in _trendBuckets(preset, period))
            () {
              final totals = _totals(bucket);
              return PeriodTotals(
                start: bucket.start,
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
          trend: trend,
        );
      });

  static const _months = 6;
  static const _years = 3;

  /// Неделя — по дням, месяц — последние месяцы, год — последние годы.
  static List<DatePeriod> _trendBuckets(
    PeriodPreset preset,
    DatePeriod period,
  ) {
    final s = period.start;
    return switch (preset) {
      PeriodPreset.week => [
        for (var d = 0; d < 7; d++)
          DatePeriod(
            start: DateTime(s.year, s.month, s.day + d),
            end: DateTime(s.year, s.month, s.day + d + 1),
          ),
      ],
      PeriodPreset.year => [
        for (var back = _years - 1; back >= 0; back--)
          DatePeriod(
            start: DateTime(s.year - back),
            end: DateTime(s.year - back + 1),
          ),
      ],
      PeriodPreset.month || PeriodPreset.custom => [
        for (var back = _months - 1; back >= 0; back--)
          DatePeriod(
            start: DateTime(s.year, s.month - back),
            end: DateTime(s.year, s.month - back + 1),
          ),
      ],
    };
  }

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
