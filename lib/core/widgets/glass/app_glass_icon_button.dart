import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

class AppGlassIconButton extends StatelessWidget {
  const AppGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GlassButton(
        icon: Icon(icon, color: color ?? Theme.of(context).colorScheme.onSurface),
        onTap: onPressed,
        label: tooltip,
        width: 40,
        height: 40,
        iconSize: 20,
      ),
    );
  }
}
