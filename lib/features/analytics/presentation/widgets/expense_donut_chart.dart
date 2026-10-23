import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/analytics/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// В центре — расходы периода, а при тапе или наведении — выбранная категория.
class ExpenseDonutChart extends StatefulWidget {
  const ExpenseDonutChart({
    super.key,
    required this.shares,
    required this.percents,
    required this.total,
    required this.currency,
  });

  final List<CategoryShare> shares;
  final List<int> percents;
  final int total;
  final Currency currency;

  @override
  State<ExpenseDonutChart> createState() => _ExpenseDonutChartState();
}

class _ExpenseDonutChartState extends State<ExpenseDonutChart> {
  static const _size = 220.0;
  static const _ring = 28.0;

  int? _touched;

  @override
  void didUpdateWidget(ExpenseDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shares != widget.shares) _touched = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final touched = _touched;
    final share = touched == null ? null : widget.shares[touched];

    return SizedBox.square(
      dimension: _size,
      child: Stack(
        alignment: .center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 2,
              centerSpaceRadius: _size / 2 - _ring - 8,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  final index = event.isInterestedForInteractions
                      ? response?.touchedSection?.touchedSectionIndex
                      : null;
                  final next = index == null || index < 0 ? null : index;
                  if (next != _touched) setState(() => _touched = next);
                },
              ),
              sections: [
                for (var i = 0; i < widget.shares.length; i++)
                  PieChartSectionData(
                    value: widget.shares[i].amount.toDouble(),
                    color: AppColors.entity(
                      widget.shares[i].category.color,
                      theme.brightness,
                    ),
                    radius: i == touched ? _ring + 6 : _ring,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const .all(_ring + 16),
            child: Column(
              mainAxisSize: .min,
              children: [
                Text(
                  formatMoney(
                    share?.amount ?? widget.total,
                    widget.currency,
                    locale,
                  ),
                  textAlign: .center,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  share == null
                      ? context.l10n.analyticsExpense.toLowerCase()
                      : '${share.category.name} · ${widget.percents[touched!]}%',
                  textAlign: .center,
                  maxLines: 2,
                  overflow: .ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
