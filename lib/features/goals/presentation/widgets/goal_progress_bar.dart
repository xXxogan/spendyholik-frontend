import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/features/goals/data/models/models.dart';

class GoalProgressBar extends StatelessWidget {
  const GoalProgressBar({super.key, required this.goal});

  final GoalModel goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: .circular(4),
      child: LinearProgressIndicator(
        value: goal.progress,
        minHeight: 8,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        color: goal.isReached
            ? AppColors.positive(theme.brightness)
            : theme.colorScheme.primary,
      ),
    );
  }
}
