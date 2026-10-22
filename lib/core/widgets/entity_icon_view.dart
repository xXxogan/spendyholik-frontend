import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/models/entity_icon.dart';
import 'package:spendyholik/core/widgets/entity_icon_data.dart';

class EntityIconView extends StatelessWidget {
  const EntityIconView({
    required this.icon,
    required this.color,
    this.size = 40,
    super.key,
  });

  final EntityIcon icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: .circular(size * 0.3),
      ),
      child: Icon(icon.data, color: color, size: size * 0.5),
    );
  }
}
