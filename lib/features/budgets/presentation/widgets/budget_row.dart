import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/features/budgets/presentation/widgets/budget_progress_bar.dart';

class BudgetRow extends StatelessWidget {
  const BudgetRow(this.budget, {super.key});

  final BudgetModel budget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final currency = CurrencyScope.of(context);

    return InkWell(
      borderRadius: .circular(12),
      onTap: () => context.router.push(BudgetDetailRoute(budgetId: budget.id)),
      child: Row(
        spacing: 12,
        children: [
          EntityIconView(
            icon: budget.category.icon,
            color: AppColors.entity(budget.category.color, theme.brightness),
            size: 32,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .stretch,
              spacing: 6,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Text(
                        budget.category.name,
                        style: theme.textTheme.titleSmall,
                        overflow: .ellipsis,
                      ),
                    ),
                    Text(
                      '${formatMoney(budget.spent, currency, locale)} / '
                      '${formatMoney(budget.limit, currency, locale)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                BudgetProgressBar(budget: budget),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
