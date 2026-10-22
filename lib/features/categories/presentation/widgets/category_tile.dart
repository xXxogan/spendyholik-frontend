import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    this.isChild = false,
    this.onTap,
  });

  final CategoryModel category;
  final bool isChild;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: .circular(12),
      child: Padding(
        padding: .only(left: isChild ? 40 : 0, top: 6, bottom: 6),
        child: Row(
          spacing: 12,
          children: [
            EntityIconView(
              icon: category.icon,
              color: AppColors.entity(category.color, theme.brightness),
              size: isChild ? 28 : 32,
            ),
            Expanded(
              child: Text(
                category.name,
                overflow: .ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            Text(
              context.l10n.categoryTransactionCount(category.transactionCount),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
