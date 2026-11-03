import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/goals/data/models/models.dart';
import 'package:spendyholik/features/goals/presentation/widgets/goal_progress_bar.dart';
import 'package:spendyholik/l10n/l10n.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.currency,
    this.onTap,
  });

  final GoalModel goal;
  final Currency currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final accent = goal.isReached
        ? AppColors.positive(theme.brightness)
        : theme.colorScheme.primary;
    final amounts = l10n.goalSavedOfTarget(
      formatMoney(goal.saved, currency, locale),
      formatMoney(goal.target, currency, locale),
    );
    final subtitle = [
      amounts,
      if (goal.isReached)
        l10n.goalReached
      else if (goal.deadline case final deadline?)
        l10n.goalDeadline(DateFormat.yMMMMd(locale).format(deadline)),
    ].join(' · ');

    return Card(
      margin: .zero,
      elevation: 0,
      color: theme.colorScheme.surface,
      clipBehavior: .antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const .all(16),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Row(
                spacing: 12,
                children: [
                  CircleAvatar(
                    backgroundColor: accent.withValues(alpha: 0.16),
                    foregroundColor: accent,
                    child: Icon(
                      goal.isReached ? Icons.check : Icons.flag_outlined,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          goal.name,
                          style: theme.textTheme.titleMedium,
                          overflow: .ellipsis,
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: .ellipsis,
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: .circular(12),
                    ),
                    child: Padding(
                      padding: const .symmetric(horizontal: 10, vertical: 4),
                      child: Text(
                        '${(goal.progress * 100).floor()}%',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GoalProgressBar(goal: goal),
            ],
          ),
        ),
      ),
    );
  }
}
