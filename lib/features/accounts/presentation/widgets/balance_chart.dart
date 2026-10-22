import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';

class BalanceChart extends StatelessWidget {
  const BalanceChart({
    super.key,
    required this.history,
    required this.color,
    required this.currency,
  });

  final List<BalancePoint> history;
  final Color color;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dayFormat = DateFormat('d MMM', locale);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final start = history.first.at;
    final lastX = _daysSince(start, history.last.at);

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final DateTime? day = switch (value) {
                    _ when value == meta.min => history.first.at,
                    _ when value == meta.max => history.last.at,
                    _ => null,
                  };
                  if (day == null) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                    child: Text(dayFormat.format(day), style: labelStyle),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.inverseSurface,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    '${formatMoney(history[spot.spotIndex].balance, currency, locale)}\n'
                    '${dayFormat.format(history[spot.spotIndex].at)}',
                    theme.textTheme.labelMedium!.copyWith(
                      color: theme.colorScheme.onInverseSurface,
                    ),
                  ),
              ],
            ),
          ),
          minX: 0,
          maxX: lastX,
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (final point in history)
                  FlSpot(_daysSince(start, point.at), point.balance / 100),
              ],
              // Баланс держится до следующей операции и меняется скачком.
              isStepLineChart: true,
              lineChartStepData: const LineChartStepData(
                stepDirection: LineChartStepData.stepDirectionForward,
              ),
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 3.5,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _daysSince(DateTime start, DateTime moment) =>
      moment.difference(start).inMinutes / Duration.minutesPerDay;
}
