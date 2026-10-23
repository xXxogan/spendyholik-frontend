import 'package:spendyholik/core/models/date_period.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';

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

class MonthlyTotals {
  const MonthlyTotals({
    required this.month,
    required this.income,
    required this.expense,
  });

  /// Первое число месяца.
  final DateTime month;
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
    required this.monthly,
  });

  final DatePeriod period;
  final int income;
  final int expense;

  /// К прошлому периоду: 0.12 — на 12% больше; null — в прошлом расходов не было.
  final double? expenseChange;

  /// По убыванию суммы, категории верхнего уровня.
  final List<CategoryShare> expenseByCategory;

  /// Последние 6 месяцев по возрастанию, последний — месяц периода.
  final List<MonthlyTotals> monthly;

  int get net => income - expense;
}
