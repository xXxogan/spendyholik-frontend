import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

/// Информационная плашка в стекле; отдельный слой стекла, без нажатия.
class AppGlassChip extends StatelessWidget {
  const AppGlassChip({super.key, required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassChip(label: label, icon: Icon(icon), useOwnLayer: true);
  }
}
