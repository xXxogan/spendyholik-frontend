import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/layout/window_size.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/home/presentation/widgets/widgets.dart';
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
          title: isDashboard
              ? const _BrandTitle()
              : Text(destinations[tabsRouter.activeIndex].label),
          actions: isDashboard
              ? [
                  IconButton(
                    tooltip: destinations.last.label,
                    icon: Icon(Icons.person_2, color: Theme.of(context).colorScheme.primary),
                    onPressed: () => tabsRouter.setActiveIndex(destinations.length - 1),
                  ),
                ]
              : null,
          body: child,
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

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: context.l10n.appTitlePrefix, style: theme.textTheme.titleLarge),
          TextSpan(
            text: context.l10n.appTitleSuffix,
            style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
