import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/features/budgets/presentation/widgets/budget_period_label.dart';
import 'package:spendyholik/features/budgets/presentation/widgets/budget_progress_bar.dart';
import 'package:spendyholik/l10n/l10n.dart';

class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({
    super.key,
    required this.budget,
    required this.currency,
  });

  final BudgetModel budget;
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
    final exceeded = budget.remaining < 0;

    return ContentCard(
      child: Column(
        children: [
          EntityIconView(
            icon: budget.category.icon,
            color: AppColors.entity(budget.category.color, brightness),
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(budget.category.name, style: theme.textTheme.titleLarge),
          Text(budgetPeriodLabel(context, budget), style: muted),
          const SizedBox(height: 14),
          Text(
            formatMoney(budget.spent, currency, locale),
            style: theme.textTheme.headlineLarge,
          ),
          Text(
            l10n.budgetsOfLimit(formatMoney(budget.limit, currency, locale)),
            style: muted,
          ),
          const SizedBox(height: 14),
          BudgetProgressBar(budget: budget),
          const SizedBox(height: 10),
          Text(
            exceeded
                ? l10n.budgetDetailExceeded(
                    formatMoney(-budget.remaining, currency, locale),
                  )
                : l10n.budgetDetailRemaining(
                    formatMoney(budget.remaining, currency, locale),
                  ),
            style: theme.textTheme.titleSmall?.copyWith(
              color: exceeded
                  ? AppColors.negative(brightness)
                  : AppColors.positive(brightness),
            ),
          ),
        ],
      ),
    );
  }
}
