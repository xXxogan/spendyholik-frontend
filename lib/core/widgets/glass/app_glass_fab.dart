import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

class AppGlassFab extends StatelessWidget {
  const AppGlassFab({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GlassButton(
        icon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        onTap: onPressed,
        label: tooltip,
        width: 56,
        height: 56,
        iconSize: 28,
      ),
    );
  }
}
