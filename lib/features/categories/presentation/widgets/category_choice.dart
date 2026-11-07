import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';

class CategoryChoice extends StatelessWidget {
  const CategoryChoice({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryModel category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.entity(category.color, theme.brightness);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: .circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 88,
          padding: const .symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: .circular(16),
            color: selected ? color.withValues(alpha: 0.12) : null,
            border: .all(
              color: selected ? color : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            spacing: 6,
            children: [
              EntityIconView(icon: category.icon, color: color, size: 36),
              Text(
                category.name,
                maxLines: 2,
                overflow: .ellipsis,
                textAlign: .center,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
