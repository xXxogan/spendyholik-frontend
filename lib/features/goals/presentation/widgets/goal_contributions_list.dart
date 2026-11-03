import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/goals/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

class GoalContributionsList extends StatelessWidget {
  const GoalContributionsList({
    super.key,
    required this.contributions,
    required this.currency,
  });

  final List<GoalContribution> contributions;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final positive = AppColors.positive(theme.brightness);
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(title: l10n.goalHistory),
        if (contributions.isEmpty)
          Text(l10n.goalHistoryEmpty)
        else
          ContentCard(
            child: Column(
              spacing: 14,
              children: [
                for (final c in contributions)
                  Row(
                    spacing: 12,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: positive.withValues(alpha: 0.16),
                        foregroundColor: positive,
                        child: const Icon(Icons.south_west, size: 18),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              l10n.goalContribution,
                              style: theme.textTheme.bodyLarge,
                            ),
                            Text(
                              '${c.from.name} · '
                              '${formatDayLabel(c.date, today, l10n, locale)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: .ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatMoney(c.amount, currency, locale, signed: true),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: positive,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
