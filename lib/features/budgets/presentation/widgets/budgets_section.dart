import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:spendyholik/features/budgets/presentation/widgets/budget_progress_bar.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Блок Главной: [limit] бюджетов с наибольшим прогрессом.
class BudgetsSection extends StatelessWidget {
  const BudgetsSection({super.key, this.limit});

  final int? limit;

  static const _budgetsTab = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider(
      create: (_) => getIt<BudgetsCubit>()..load(),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          SectionHeader(
            title: l10n.dashboardBudgets,
            actionLabel: l10n.dashboardAllBudgets,
            onAction: () =>
                AutoTabsRouter.of(context).setActiveIndex(_budgetsTab),
          ),
          BlocBuilder<BudgetsCubit, BudgetsState>(
            builder: (context, state) => switch (state) {
              BudgetsLoading() => const SkeletonList(itemCount: 2),
              BudgetsLoaded(:final budgets) => ContentCard(
                child: Column(
                  spacing: 16,
                  children: [
                    for (final budget in _top(budgets)) _BudgetRow(budget),
                  ],
                ),
              ),
              BudgetsEmpty() => Text(l10n.budgetsEmpty),
              BudgetsError(:final failure) => FailureView(
                failure: failure,
                onRetry: context.read<BudgetsCubit>().load,
              ),
            },
          ),
        ],
      ),
    );
  }

  List<BudgetModel> _top(List<BudgetModel> budgets) {
    final sorted = [...budgets]
      ..sort((a, b) => b.progress.compareTo(a.progress));
    return limit == null ? sorted : sorted.take(limit!).toList();
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow(this.budget);

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
