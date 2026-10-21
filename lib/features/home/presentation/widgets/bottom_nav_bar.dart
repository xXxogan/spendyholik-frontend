import 'package:auto_route/auto_route.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.tabsRouter});

  final TabsRouter tabsRouter;

  @override
  Widget build(BuildContext context) {
    return GlassTabBar.bottom(
      selectedIndex: tabsRouter.activeIndex,
      onTabSelected: tabsRouter.setActiveIndex,
      tabs: const [
        GlassTab(icon: Icon(Icons.home), label: "Главная"),
        GlassTab(icon: Icon(Icons.list), label: "Транзакции"),
        GlassTab(icon: Icon(Icons.analytics), label: "Аналитика"),
        GlassTab(icon: Icon(Icons.money), label: "Бюджет"),
        GlassTab(icon: Icon(Icons.person), label: "Профиль"),
      ],
    );
  }
}
