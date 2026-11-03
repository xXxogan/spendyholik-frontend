import 'package:spendyholik/core/models/date_period.dart';
import 'package:spendyholik/features/categories/categories.dart';

enum BudgetPeriod { monthly, weekly, once }

enum BudgetStatus { ok, warning, exceeded }

class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.category,
    required this.limit,
    required this.spent,
    required this.period,
    required this.currentPeriod,
  });

  final String id;
  final CategoryRef category;
  final int limit;

  /// Расходы категории и её подкатегорий за [currentPeriod]; считает сервер.
  final int spent;
  final BudgetPeriod period;
  final DatePeriod currentPeriod;

  int get remaining => limit - spent;

  /// Не ограничен 1: при превышении больше единицы.
  double get progress => spent / limit;

  /// warning — от 80% включительно, exceeded — строго больше лимита.
  BudgetStatus get status {
    if (spent > limit) return BudgetStatus.exceeded;
    if (spent * 5 >= limit * 4) return BudgetStatus.warning;
    return BudgetStatus.ok;
  }
}

class BudgetDraft {
  const BudgetDraft({
    required this.categoryId,
    required this.limit,
    required this.period,
    this.onceStart,
    this.onceEnd,
  });

  final String categoryId;
  final int limit;
  final BudgetPeriod period;

  /// Только для [BudgetPeriod.once]; [onceEnd] не включительно.
  final DateTime? onceStart;
  final DateTime? onceEnd;
}
