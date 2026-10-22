import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/presentation/widgets/category_kind_label.dart';
import 'package:spendyholik/features/categories/presentation/widgets/category_tile.dart';
import 'package:spendyholik/l10n/l10n.dart';

class CategoryGroup extends StatefulWidget {
  const CategoryGroup({
    super.key,
    required this.kind,
    required this.nodes,
    this.initiallyExpanded = false,
    this.onCategoryTap,
  });

  final CategoryKind kind;
  final List<CategoryNode> nodes;
  final bool initiallyExpanded;
  final ValueChanged<CategoryModel>? onCategoryTap;

  @override
  State<CategoryGroup> createState() => _CategoryGroupState();
}

class _CategoryGroupState extends State<CategoryGroup> {
  late var _expanded = widget.initiallyExpanded;

  VoidCallback? _tapHandler(CategoryModel category) {
    final onTap = widget.onCategoryTap;
    return onTap == null ? null : () => onTap(category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final count = widget.nodes.fold(
      0,
      (sum, node) => sum + 1 + node.children.length,
    );

    return ContentCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: .circular(12),
              child: Padding(
                padding: const .symmetric(vertical: 4),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Text(
                        categoryKindLabel(context.l10n, widget.kind),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Text('$count', style: mutedStyle),
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: .topCenter,
            child: _expanded
                ? Padding(
                    padding: const .only(top: 8),
                    child: widget.nodes.isEmpty
                        ? Text(
                            context.l10n.categoriesGroupEmpty,
                            style: mutedStyle,
                          )
                        : Column(
                            crossAxisAlignment: .stretch,
                            children: [
                              for (final node in widget.nodes) ...[
                                CategoryTile(
                                  category: node.category,
                                  onTap: _tapHandler(node.category),
                                ),
                                for (final child in node.children)
                                  CategoryTile(
                                    category: child,
                                    isChild: true,
                                    onTap: _tapHandler(child),
                                  ),
                              ],
                            ],
                          ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
