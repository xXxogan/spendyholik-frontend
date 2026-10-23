import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/app_nav_destination.dart';

class AppBottomNav extends StatelessWidget implements PreferredSizeWidget {
  const AppBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _barHeight = 64.0;
  static const _verticalPadding = 20.0;

  /// Без него GlassScaffold считает таб-бар высотой 60 по умолчанию,
  /// а капсула с отступами — 104.
  @override
  Size get preferredSize =>
      const Size.fromHeight(_barHeight + _verticalPadding * 2);

  @override
  Widget build(BuildContext context) {
    return GlassTabBar.bottom(
      barHeight: _barHeight,
      verticalPadding: _verticalPadding,
      selectedIndex: selectedIndex,
      onTabSelected: onSelected,
      tabs: [
        for (final destination in destinations)
          GlassTab(
            icon: Icon(destination.icon),
            activeIcon: Icon(destination.selectedIcon),
            label: destination.label,
          ),
      ],
    );
  }
}
