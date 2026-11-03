import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/layout/window_size.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/budgets/budgets.dart';
import 'package:spendyholik/features/home/presentation/widgets/widgets.dart';
import 'package:spendyholik/features/notifications/notifications.dart';
import 'package:spendyholik/features/transactions/transactions.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class TabsPage extends StatelessWidget {
  const TabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: homeTabRoutes,
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        final destinations = homeDestinations(context.l10n);
        final isDashboard = tabsRouter.activeIndex == 0;

        return AppGlassScaffold(
          titleWidget: isDashboard ? const BrandTitle() : null,
          title: destinations[tabsRouter.activeIndex].label,
          largeTitle: !isDashboard,
          actions: switch (homeTabRoutes[tabsRouter.activeIndex].routeName) {
            DashboardRoute.name => [
              const NotificationsBellButton(),
              AppGlassIconButton(
                tooltip: destinations.last.label,
                icon: Icons.person_2,
                color: Theme.of(context).colorScheme.primary,
                onPressed: () =>
                    tabsRouter.setActiveIndex(destinations.length - 1),
              ),
            ],
            TransactionsRoute.name => [
              AppGlassIconButton(
                tooltip: context.l10n.transactionsAdd,
                icon: Icons.add,
                onPressed: () =>
                    context.router.push(const TransactionCreateRoute()),
              ),
            ],
            BudgetsRoute.name => [const BudgetsAddButton()],
            _ => null,
          },
          body: child,
          floatingButton: AppGlassFab(
            icon: Icons.add,
            tooltip: context.l10n.quickAddTitle,
            onPressed: () => showQuickAddSheet(context),
          ),
          bottomBar: context.windowSize == WindowSize.compact
              ? AppBottomNav(
                  destinations: destinations,
                  selectedIndex: tabsRouter.activeIndex,
                  onSelected: tabsRouter.setActiveIndex,
                )
              : null,
        );
      },
    );
  }
}
