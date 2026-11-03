import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// «Ноябрь», «Эта неделя» или «24 окт. – 23 нояб.».
String budgetPeriodLabel(BuildContext context, BudgetModel budget) {
  final locale = Localizations.localeOf(context).toString();
  final current = budget.currentPeriod;

  return switch (budget.period) {
    BudgetPeriod.monthly => toBeginningOfSentenceCase(
      DateFormat.LLLL(locale).format(current.start),
      locale,
    ),
    BudgetPeriod.weekly => context.l10n.budgetsThisWeek,
    BudgetPeriod.once => budgetRangeLabel(locale, current.start, current.end),
  };
}

/// [end] не включительно — показываем последний день.
String budgetRangeLabel(String locale, DateTime start, DateTime end) {
  final format = DateFormat.MMMd(locale);
  final lastDay = DateTime(end.year, end.month, end.day - 1);
  return '${format.format(start)} – ${format.format(lastDay)}';
}
