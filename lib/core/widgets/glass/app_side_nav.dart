import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/app_nav_destination.dart';
import 'package:spendyholik/core/widgets/glass/side_nav_item.dart';
import 'package:spendyholik/core/widgets/glass/side_nav_metrics.dart';

// В liquid_glass_widgets нет вертикальной навигации (спайк S-01) — панель
// собрана из GlassContainer.
class AppSideNav extends StatelessWidget {
  const AppSideNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.extended,
  });

  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      useOwnLayer: true,
      width: extended ? SideNavMetrics.extendedWidth : SideNavMetrics.railWidth,
      padding: const .all(8),
      shape: const LiquidRoundedSuperellipse(borderRadius: 28),
      child: Material(
        type: .transparency,
        child: Column(
          children: [
            for (var i = 0; i < destinations.length; i++)
              SideNavItem(
                destination: destinations[i],
                selected: i == selectedIndex,
                extended: extended,
                onTap: () => onSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}
