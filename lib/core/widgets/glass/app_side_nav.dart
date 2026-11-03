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
    this.links = const [],
    this.selectedLink,
    this.onLinkSelected,
    this.footer,
  });

  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool extended;

  /// Второй блок под разделителем — разделы вне вкладок (как в макете).
  final List<AppNavDestination> links;
  final int? selectedLink;
  final ValueChanged<int>? onLinkSelected;

  /// Прижат к низу панели — пользователь.
  final Widget? footer;

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
            if (links.isNotEmpty)
              const Divider(height: 17, indent: 8, endIndent: 8),
            for (var i = 0; i < links.length; i++)
              SideNavItem(
                destination: links[i],
                selected: i == selectedLink,
                extended: extended,
                onTap: () => onLinkSelected?.call(i),
              ),
            if (footer case final footer?) ...[const Spacer(), footer],
          ],
        ),
      ),
    );
  }
}
