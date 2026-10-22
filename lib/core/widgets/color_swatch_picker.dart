import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/models/entity_color.dart';

class ColorSwatchPicker extends StatelessWidget {
  const ColorSwatchPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final EntityColor selected;
  final ValueChanged<EntityColor> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final color in EntityColor.values)
          Semantics(
            button: true,
            selected: color == selected,
            label: color.name,
            child: InkResponse(
              onTap: () => onSelected(color),
              radius: 22,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                padding: const .all(3),
                decoration: BoxDecoration(
                  shape: .circle,
                  border: .all(
                    color: color == selected
                        ? theme.colorScheme.onSurface
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: .circle,
                    color: AppColors.entity(color, theme.brightness),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
