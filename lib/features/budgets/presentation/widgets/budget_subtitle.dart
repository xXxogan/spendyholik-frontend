import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// «Ноябрь · осталось 5 770 ₽» или «Ноябрь · превышен на 400 ₽».
String budgetSubtitle(
  BuildContext context,
  BudgetModel budget,
  Currency currency,
) {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).toString();
  final current = budget.currentPeriod;
  final period = switch (budget.period) {
    BudgetPeriod.monthly => toBeginningOfSentenceCase(
      DateFormat.LLLL(locale).format(current.start),
      locale,
    ),
    BudgetPeriod.weekly => l10n.budgetsThisWeek,
    BudgetPeriod.once => () {
      final format = DateFormat.MMMd(locale);
      final lastDay = DateTime(
        current.end.year,
        current.end.month,
        current.end.day - 1,
      );
      return '${format.format(current.start)} – ${format.format(lastDay)}';
    }(),
  };

  return budget.remaining < 0
      ? l10n.budgetsExceeded(
          period,
          formatMoney(-budget.remaining, currency, locale),
        )
      : l10n.budgetsRemaining(
          period,
          formatMoney(budget.remaining, currency, locale),
        );
}
