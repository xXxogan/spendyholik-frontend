import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/app_nav_destination.dart';

class SideNavItem extends StatelessWidget {
  const SideNavItem({
    super.key,
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
    final foreground = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final count = destination.badgeCount;
    final iconData = Icon(
      selected ? destination.selectedIcon : destination.icon,
      color: foreground,
    );
    // На рейле подписи нет — число садится на иконку.
    final icon = !extended && count > 0
        ? Badge(label: Text('$count'), child: iconData)
        : iconData;

    final item = Padding(
      padding: const .symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: .circular(20),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.14)
                : null,
            borderRadius: .circular(20),
          ),
          child: extended
              ? Padding(
                  padding: const .symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          destination.label,
                          overflow: .ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: foreground),
                        ),
                      ),
                      if (count > 0) Badge(label: Text('$count')),
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
      value: count > 0 ? '$count' : null,
      child: extended ? item : Tooltip(message: destination.label, child: item),
    );
  }
}
