import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';

class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({super.key, required this.budget});

  final BudgetModel budget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return ClipRRect(
      borderRadius: .circular(4),
      child: LinearProgressIndicator(
        value: budget.progress.clamp(0, 1),
        minHeight: 8,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        color: switch (budget.status) {
          BudgetStatus.ok => AppColors.entity(
            budget.category.color,
            brightness,
          ),
          BudgetStatus.warning => AppColors.warning(brightness),
          BudgetStatus.exceeded => AppColors.negative(brightness),
        },
      ),
    );
  }
}
