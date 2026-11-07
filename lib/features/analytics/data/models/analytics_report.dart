import 'package:spendyholik/core/models/date_period.dart';
import 'package:spendyholik/features/categories/categories.dart';

class CategoryShare {
  const CategoryShare({
    required this.category,
    required this.amount,
    required this.share,
  });

  final CategoryRef category;
  final int amount;

  /// 0..1 от расходов периода.
  final double share;
}

/// Отрезок графика динамики: день, месяц или год — по шагу периода отчёта.
class PeriodTotals {
  const PeriodTotals({
    required this.start,
    required this.income,
    required this.expense,
  });

  /// Начало дня, месяца или года.
  final DateTime start;
  final int income;
  final int expense;
}

class AnalyticsReport {
  const AnalyticsReport({
    required this.period,
    required this.income,
    required this.expense,
    required this.expenseChange,
    required this.expenseByCategory,
    required this.trend,
  });

  final DatePeriod period;
  final int income;
  final int expense;

  /// К прошлому периоду: 0.12 — на 12% больше; null — в прошлом расходов не было.
  final double? expenseChange;

  /// По убыванию суммы, категории верхнего уровня.
  final List<CategoryShare> expenseByCategory;

  /// По возрастанию: неделя — 7 дней недели, месяц — последние 6 месяцев,
  /// год — последние 3 года; последний отрезок содержит период отчёта.
  final List<PeriodTotals> trend;

  int get net => income - expense;
}
