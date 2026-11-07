import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:spendyholik/features/budgets/presentation/widgets/budget_row.dart';
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
                    for (final budget in _top(budgets)) BudgetRow(budget),
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
