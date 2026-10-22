import 'package:auto_route/auto_route.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/features/home/presentation/widgets/home_destinations.dart';

/// [tabs] — null, когда вкладок нет в стеке: страницу деталей открыли
/// по URL или обновили на Web.
Future<void> selectHomeTab(StackRouter router, TabsRouter? tabs, int index) async {
  if (tabs != null) {
    router.popUntilRouteWithName(TabsRoute.name);
    tabs.setActiveIndex(index);
    return;
  }
  await router.replaceAll([TabsRoute(children: [homeTabRoutes[index]])]);
}
