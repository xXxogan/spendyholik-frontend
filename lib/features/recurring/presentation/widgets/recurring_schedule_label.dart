import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/features/recurring/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// «5-е число каждого месяца», «Каждую неделю, пятница», «Каждый год, 15 марта».
String recurringScheduleLabel(BuildContext context, RecurringModel template) {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).toString();
  final anchor = template.anchor;

  return switch (template.frequency) {
    RecurrenceFrequency.monthly => l10n.recurringMonthly(anchor.day),
    RecurrenceFrequency.weekly => l10n.recurringWeekly(
      DateFormat.EEEE(locale).format(anchor),
    ),
    RecurrenceFrequency.yearly => l10n.recurringYearly(
      DateFormat.MMMMd(locale).format(anchor),
    ),
  };
}
