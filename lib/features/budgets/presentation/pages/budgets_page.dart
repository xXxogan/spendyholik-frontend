import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:spendyholik/features/budgets/presentation/cubit/budgets_tab_cubit.dart';
import 'package:spendyholik/features/budgets/presentation/widgets/widgets.dart';
import 'package:spendyholik/features/goals/goals.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BudgetsCubit>()..load(),
      child: const BudgetsView(),
    );
  }
}

class BudgetsView extends StatelessWidget {
  const BudgetsView({super.key});

  static const _segmentsMaxWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<BudgetsCubit>();
    final state = context.watch<BudgetsCubit>().state;
    final tabs = getIt<BudgetsTabCubit>();

    return BlocBuilder<BudgetsTabCubit, BudgetsTab>(
      bloc: tabs,
      builder: (context, tab) => BaseLayout.slivers(
        largeTitle: l10n.navBudgets,
        slivers: [
          ContentSliverPadding(
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: .centerLeft,
                child: Padding(
                  padding: const .symmetric(vertical: 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _segmentsMaxWidth,
                    ),
                    child: BudgetsSegment(
                      selected: tab,
                      onSelected: tabs.select,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (tab == BudgetsTab.goals)
            const GoalsList()
          else
            switch (state) {
              BudgetsLoading() => const SliverToBoxAdapter(
                child: SkeletonList(itemCount: 4, itemHeight: 120),
              ),
              BudgetsLoaded(:final budgets) => ContentSliverPadding(
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 560,
                    mainAxisExtent: 124,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) => BudgetCard(
                    budget: budgets[index],
                    currency: CurrencyScope.of(context),
                    onTap: () => context.router.push(
                      BudgetDetailRoute(budgetId: budgets[index].id),
                    ),
                  ),
                ),
              ),
              BudgetsEmpty() => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(l10n.budgetsEmpty)),
              ),
              BudgetsError(:final failure) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: FailureView(failure: failure, onRetry: cubit.load),
                ),
              ),
            },
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
