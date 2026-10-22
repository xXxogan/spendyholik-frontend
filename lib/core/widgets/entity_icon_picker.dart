import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/models/entity_color.dart';
import 'package:spendyholik/core/models/entity_icon.dart';
import 'package:spendyholik/core/widgets/entity_icon_data.dart';

/// Выбранная иконка подсвечена [color] — цветом сущности, которую правят.
class EntityIconPicker extends StatelessWidget {
  const EntityIconPicker({
    super.key,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final EntityIcon selected;
  final EntityColor color;
  final ValueChanged<EntityIcon> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.entity(color, theme.brightness);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final icon in EntityIcon.values)
          Semantics(
            button: true,
            selected: icon == selected,
            label: icon.name,
            child: InkWell(
              onTap: () => onSelected(icon),
              borderRadius: .circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: .circular(12),
                  color: icon == selected
                      ? accent.withValues(alpha: 0.16)
                      : null,
                  border: .all(
                    color: icon == selected
                        ? accent
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Icon(
                  icon.data,
                  size: 22,
                  color: icon == selected
                      ? accent
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
