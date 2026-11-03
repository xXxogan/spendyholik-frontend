import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/notifications/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Заголовок и подпись уведомления из ARB по виду и полям.
(String, String) notificationText(
  BuildContext context,
  NotificationModel n,
  Currency currency,
) {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).toString();
  final now = DateTime.now();
  final when = [
    formatDayLabel(n.createdAt, now, l10n, locale),
    DateFormat.Hm(locale).format(n.createdAt),
  ].join(', ');
  final amount = n.amount ?? 0;
  final percent = n.percent ?? 0;

  final (title, details) = switch (n.kind) {
    NotificationKind.budgetAlmostSpent => (
      l10n.notificationBudgetTitle(n.subject),
      l10n.notificationBudgetDetails(percent),
    ),
    NotificationKind.incomeReceived => (
      l10n.notificationIncomeTitle,
      '${formatMoney(amount, currency, locale, signed: true)} · ${n.subject}',
    ),
    NotificationKind.recurringTomorrow => (
      l10n.notificationRecurringTitle,
      '${n.subject} · ${formatMoney(-amount, currency, locale)}',
    ),
    NotificationKind.goalProgress => (
      l10n.notificationGoalTitle(percent),
      n.subject,
    ),
  };
  return (title, '$details · $when');
}
