import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/analytics/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Столбцы доходов и расходов; шаг — по [preset]: дни недели, месяцы, годы.
class TrendBarChart extends StatelessWidget {
  const TrendBarChart({
    super.key,
    required this.trend,
    required this.preset,
    required this.currency,
  });

  final List<PeriodTotals> trend;
  final PeriodPreset preset;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final locale = Localizations.localeOf(context).toString();
    final income = AppColors.positive(brightness);
    final expense = AppColors.negative(brightness);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final top = trend.fold(
      0,
      (value, m) => max(value, max(m.income, m.expense)),
    );
    // Запас сверху, чтобы подсказка над высоким столбцом не обрезалась.
    final maxY = top == 0 ? 1.0 : top / 100 * 1.15;
    final labelFormat = switch (preset) {
      PeriodPreset.week => DateFormat.E(locale),
      PeriodPreset.year => DateFormat.y(locale),
      PeriodPreset.month || PeriodPreset.custom => DateFormat.LLL(locale),
    };

    Widget legend(Color color, String label) => Row(
      mainAxisSize: .min,
      spacing: 6,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: .circular(3)),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );

    return Column(
      crossAxisAlignment: .start,
      spacing: 16,
      children: [
        Wrap(
          spacing: 16,
          children: [
            legend(income, l10n.analyticsIncome),
            legend(expense, l10n.analyticsExpense),
          ],
        ),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: .spaceAround,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: maxY / 3,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: theme.colorScheme.outlineVariant,
                  strokeWidth: 1,
                  dashArray: const [3, 4],
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 64,
                    interval: maxY / 3,
                    getTitlesWidget: (value, meta) => value == meta.max
                        ? const SizedBox.shrink()
                        : SideTitleWidget(
                            meta: meta,
                            child: Text(
                              formatMoneyCompact(
                                (value * 100).round(),
                                currency,
                                locale,
                              ),
                              style: labelStyle,
                            ),
                          ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        labelFormat.format(trend[value.toInt()].start),
                        style: labelStyle,
                      ),
                    ),
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final bucket = trend[group.x];
                    final amount = rodIndex == 0
                        ? bucket.income
                        : bucket.expense;
                    return BarTooltipItem(
                      formatMoney(amount, currency, locale),
                      theme.textTheme.labelMedium!.copyWith(
                        color: theme.colorScheme.onInverseSurface,
                      ),
                    );
                  },
                ),
              ),
              barGroups: [
                for (var i = 0; i < trend.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: trend[i].income / 100,
                        color: income,
                        width: 10,
                        borderRadius: .circular(3),
                      ),
                      BarChartRodData(
                        toY: trend[i].expense / 100,
                        color: expense,
                        width: 10,
                        borderRadius: .circular(3),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
