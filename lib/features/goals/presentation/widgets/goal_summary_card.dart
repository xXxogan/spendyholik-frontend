import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/goals/data/models/models.dart';
import 'package:spendyholik/features/goals/presentation/widgets/goal_progress_bar.dart';
import 'package:spendyholik/l10n/l10n.dart';

class GoalSummaryCard extends StatelessWidget {
  const GoalSummaryCard({
    super.key,
    required this.goal,
    required this.currency,
  });

  final GoalModel goal;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    return ContentCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            goal.name,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatMoney(goal.saved, currency, locale),
            style: theme.textTheme.headlineLarge,
          ),
          Text(
            context.l10n.goalOfTargetPercent(
              formatMoney(goal.target, currency, locale),
              (goal.progress * 100).floor(),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          GoalProgressBar(goal: goal),
        ],
      ),
    );
  }
}
