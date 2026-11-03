import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/budgets/budgets.dart';
import 'package:spendyholik/features/goals/goals.dart';
import 'package:spendyholik/features/transactions/transactions.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const _transactionsTab = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BaseLayout.slivers(
      slivers: [
        ContentSliverPadding(
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const .only(top: 12, bottom: 120),
              child: TwoColumnLayout(
                primary: const [
                  TotalBalanceCard(),
                  AccountsSection(),
                  BudgetsSection(limit: 2),
                  NearestGoalCard(),
                ],
                secondary: [
                  TransactionsSection(
                    filter: const TransactionFilter(limit: 5),
                    title: l10n.dashboardRecentTransactions,
                    actionLabel: l10n.dashboardAllTransactions,
                    onSeeAll: () =>
                        AutoTabsRouter.of(context)
                            .setActiveIndex(_transactionsTab),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
