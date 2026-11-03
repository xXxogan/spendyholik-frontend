import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/budgets/presentation/cubit/budget_detail_cubit.dart';
import 'package:spendyholik/features/budgets/presentation/widgets/widgets.dart';
import 'package:spendyholik/features/transactions/transactions.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class BudgetDetailPage extends StatelessWidget {
  const BudgetDetailPage({
    super.key,
    @PathParam('budgetId') required this.budgetId,
  });

  final String budgetId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BudgetDetailCubit>()..load(budgetId),
      child: const BudgetDetailView(),
    );
  }
}

class BudgetDetailView extends StatelessWidget {
  const BudgetDetailView({super.key});

  static const _fallback = TabsRoute(children: [BudgetsRoute()]);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<BudgetDetailCubit>();
    final state = context.watch<BudgetDetailCubit>().state;
    final budget = switch (state) {
      BudgetDetailLoaded(:final budget) => budget,
      _ => null,
    };

    return BlocListener<BudgetDetailCubit, BudgetDetailState>(
      listenWhen: (_, state) => state is BudgetDetailDeleted,
      listener: (context, _) {
        // Удалили формой правки — она уже сняла и детали; уходим сами,
        // только если детали на экране.
        if (ModalRoute.of(context)?.isCurrent != true) return;
        showAppToast(context, l10n.budgetDeleted);
        navigateBack(context.router, _fallback);
      },
      child: AppGlassScaffold(
        leading: const AppBackButton(fallback: _fallback),
        title: l10n.budgetDetailTitle,
        largeTitle: true,
        actions: [
          if (budget != null)
            AppGlassIconButton(
              icon: Icons.edit_outlined,
              tooltip: l10n.budgetEditAction,
              onPressed: () =>
                  context.router.push(BudgetEditRoute(budgetId: budget.id)),
            ),
        ],
        body: BaseLayout.slivers(
          largeTitle: l10n.budgetDetailTitle,
          slivers: [
            switch (state) {
              BudgetDetailLoaded(:final budget) => ContentSliverPadding(
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const .only(top: 12, bottom: 120),
                    child: TwoColumnLayout(
                      primary: [
                        BudgetSummaryCard(
                          budget: budget,
                          currency: CurrencyScope.of(context),
                        ),
                      ],
                      secondary: [
                        TransactionsSection(
                          filter: TransactionFilter(
                            type: TransactionType.expense,
                            categoryId: budget.category.id,
                            period: budget.currentPeriod,
                          ),
                          title: l10n.budgetDetailTransactions,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              BudgetDetailError(:final failure) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: FailureView(failure: failure, onRetry: cubit.reload),
                ),
              ),
              BudgetDetailLoading() ||
              BudgetDetailDeleted() => const SliverToBoxAdapter(
                child: SkeletonList(itemCount: 3, itemHeight: 120),
              ),
            },
          ],
        ),
      ),
    );
  }
}
