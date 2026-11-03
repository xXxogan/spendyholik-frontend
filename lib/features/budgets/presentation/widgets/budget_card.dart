import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/features/budgets/presentation/widgets/budget_progress_bar.dart';
import 'package:spendyholik/features/budgets/presentation/widgets/budget_subtitle.dart';
import 'package:spendyholik/l10n/l10n.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.budget,
    required this.currency,
    this.onTap,
  });

  final BudgetModel budget;
  final Currency currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final locale = Localizations.localeOf(context).toString();
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

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
                  EntityIconView(
                    icon: budget.category.icon,
                    color: AppColors.entity(budget.category.color, brightness),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          budget.category.name,
                          style: theme.textTheme.titleMedium,
                          overflow: .ellipsis,
                        ),
                        Text(
                          budgetSubtitle(context, budget, currency),
                          style: budget.status == BudgetStatus.exceeded
                              ? muted?.copyWith(
                                  color: AppColors.negative(brightness),
                                )
                              : muted,
                          overflow: .ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              BudgetProgressBar(budget: budget),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  Text(
                    formatMoney(budget.spent, currency, locale),
                    style: muted,
                  ),
                  Text(
                    context.l10n.budgetsOfLimit(
                      formatMoney(budget.limit, currency, locale),
                    ),
                    style: muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
