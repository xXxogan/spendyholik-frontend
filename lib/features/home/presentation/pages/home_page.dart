import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/layout/window_size.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/home/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoRouter(builder: (context, content) => _HomeShell(content: content));
  }
}

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.content});

  final Widget content;

  @override
  Widget build(BuildContext context) {
    final windowSize = context.windowSize;
    if (windowSize == WindowSize.compact) return content;

    final extended = windowSize == WindowSize.expanded;
    final router = AutoRouter.of(context);

    return Stack(
      children: [
        ShellScope(
          leftInset: SideNavMetrics.contentInset(extended: extended),
          child: content,
        ),
        Positioned(
          left: SideNavMetrics.gap,
          top: SideNavMetrics.gap,
          bottom: SideNavMetrics.gap,
          child: SafeArea(
            right: false,
            // Смена вкладки уведомляет корневой роутер, а не родительский стек.
            child: ListenableBuilder(
              listenable: router.root,
              builder: (context, _) {
                final tabs = router.innerRouterOf<TabsRouter>(TabsRoute.name);
                return AppSideNav(
                  destinations: homeDestinations(context.l10n),
                  selectedIndex: tabs?.activeIndex ?? 0,
                  extended: extended,
                  onSelected: (index) {
                    router.popUntilRouteWithName(TabsRoute.name);
                    tabs?.setActiveIndex(index);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
