import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/analytics/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

class AnalyticsSummary extends StatelessWidget {
  const AnalyticsSummary({
    super.key,
    required this.report,
    required this.preset,
    required this.currency,
  });

  final AnalyticsReport report;
  final PeriodPreset preset;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final locale = Localizations.localeOf(context).toString();
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    Widget tile(String label, String value, Color color) => Expanded(
      child: ContentCard(
        child: Column(
          crossAxisAlignment: .start,
          spacing: 4,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(color: color),
            ),
            Text(label, style: muted),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 12,
      children: [
        Text(_periodLabel(locale), style: muted),
        Row(
          spacing: 12,
          children: [
            tile(
              l10n.analyticsIncome,
              formatMoney(report.income, currency, locale, signed: true),
              AppColors.positive(brightness),
            ),
            tile(
              l10n.analyticsExpense,
              formatMoney(-report.expense, currency, locale),
              AppColors.negative(brightness),
            ),
          ],
        ),
        Text(
          l10n.analyticsNet(
            formatMoney(report.net, currency, locale, signed: true),
          ),
          style: theme.textTheme.titleSmall,
        ),
        if (_comparison(l10n) case final text?) Text(text, style: muted),
      ],
    );
  }

  String _periodLabel(String locale) {
    final period = report.period;
    final end = period.end;
    final lastDay = DateTime(end.year, end.month, end.day - 1);
    return switch (preset) {
      PeriodPreset.week =>
        '${DateFormat.MMMd(locale).format(period.start)} – '
            '${DateFormat.MMMd(locale).format(lastDay)}',
      PeriodPreset.year => DateFormat.y(locale).format(period.start),
      PeriodPreset.month ||
      PeriodPreset.custom => DateFormat.yMMMM(locale).format(period.start),
    };
  }

  String? _comparison(AppLocalizations l10n) {
    final change = report.expenseChange;
    if (change == null) return null;
    final when = switch (preset) {
      PeriodPreset.week => l10n.analyticsPrevWeek,
      PeriodPreset.year => l10n.analyticsPrevYear,
      PeriodPreset.month || PeriodPreset.custom => l10n.analyticsPrevMonth,
    };
    final percent = (change.abs() * 100).round();
    if (percent == 0) return l10n.analyticsExpenseSame(when);
    return change > 0
        ? l10n.analyticsExpenseMore(percent, when)
        : l10n.analyticsExpenseLess(percent, when);
  }
}
