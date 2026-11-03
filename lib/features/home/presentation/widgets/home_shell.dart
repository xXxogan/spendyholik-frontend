import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/layout/window_size.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/home/presentation/widgets/widgets.dart';
import 'package:spendyholik/features/notifications/notifications.dart';
import 'package:spendyholik/features/user/user.dart';
import 'package:spendyholik/l10n/l10n.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.content});

  final Widget content;

  static final _profileTab = homeTabRoutes.indexWhere(
    (route) => route.routeName == ProfileRoute.name,
  );

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
            child: BlocProvider(
              create: (_) => getIt<UnreadCountCubit>()..load(),
              // Смена вкладки уведомляет корневой роутер, а не родительский стек.
              child: ListenableBuilder(
                listenable: router.root,
                builder: (context, _) {
                  final tabs = router.innerRouterOf<TabsRouter>(TabsRoute.name);
                  final link = homeLinkRoutes.indexWhere(
                    (route) => route.routeName == router.current.name,
                  );
                  final unread = context.watch<UnreadCountCubit>().state;
                  return AppSideNav(
                    destinations: homeDestinations(context.l10n),
                    selectedIndex: link == -1 ? tabs?.activeIndex ?? -1 : -1,
                    extended: extended,
                    onSelected: (index) => selectHomeTab(router, tabs, index),
                    links: homeLinks(context.l10n, unreadNotifications: unread),
                    selectedLink: link,
                    onLinkSelected: (index) {
                      if (index == link) return;
                      openHomeLink(router, tabs, homeLinkRoutes[index]);
                    },
                    footer: SessionUserTile(
                      extended: extended,
                      onTap: () => selectHomeTab(router, tabs, _profileTab),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
