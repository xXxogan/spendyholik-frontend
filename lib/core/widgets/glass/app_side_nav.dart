import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/app_nav_destination.dart';

abstract final class SideNavMetrics {
  static const railWidth = 64.0;
  static const extendedWidth = 240.0;
  static const gap = 12.0;

  static double contentInset({required bool extended}) =>
      gap * 2 + (extended ? extendedWidth : railWidth);
}

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
      padding: const EdgeInsets.all(8),
      shape: const LiquidRoundedSuperellipse(borderRadius: 28),
      child: Material(
        type: .transparency,
        child: Column(
          children: [
            for (var i = 0; i < destinations.length; i++)
              _SideNavItem(
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

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final AppNavDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;
    final icon = Icon(
      selected ? destination.selectedIcon : destination.icon,
      color: foreground,
    );

    final item = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary.withValues(alpha: 0.14) : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: extended
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          destination.label,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(child: icon),
        ),
      ),
    );

    return Semantics(
      selected: selected,
      button: true,
      label: extended ? null : destination.label,
      child: extended ? item : Tooltip(message: destination.label, child: item),
    );
  }
}
