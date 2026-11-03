import 'package:material_ui/material_ui.dart';

class AppNavDestination {
  const AppNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// 0 — без счётчика.
  final int badgeCount;
}
