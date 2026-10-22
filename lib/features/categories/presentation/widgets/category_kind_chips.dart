import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/presentation/widgets/category_kind_label.dart';
import 'package:spendyholik/l10n/l10n.dart';

class CategoryKindChips extends StatelessWidget {
  const CategoryKindChips({super.key, required this.selected, this.onSelected});

  final CategoryKind selected;

  /// null — тип только показывается, выбрать другой нельзя.
  final ValueChanged<CategoryKind>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final kind in CategoryKind.values)
          ChoiceChip(
            label: Text(categoryKindLabel(context.l10n, kind)),
            selected: kind == selected,
            onSelected: switch (onSelected) {
              final onSelected? => (_) => onSelected(kind),
              null => null,
            },
          ),
      ],
    );
  }
}
