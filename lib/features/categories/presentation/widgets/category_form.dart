import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/categories/presentation/cubit/category_form_cubit.dart';
import 'package:spendyholik/features/categories/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

class CategoryForm extends StatelessWidget {
  const CategoryForm({super.key, required this.state, required this.cubit});

  final CategoryFormState state;
  final CategoryFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labelStyle = Theme.of(context).textTheme.titleSmall;
    final nameError = switch (state.fieldErrors[CategoryField.name]) {
      final error? => fieldErrorText(l10n, error),
      null => null,
    };
    final options = state.parentOptions;

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        TextFormField(
          initialValue: state.name,
          onChanged: cubit.nameChanged,
          textCapitalization: .sentences,
          decoration: InputDecoration(
            labelText: l10n.categoryFormName,
            hintText: l10n.categoryFormNameHint,
            errorText: nameError,
          ),
        ),
        Text(l10n.categoryFormKind, style: labelStyle),
        CategoryKindChips(
          selected: state.kind,
          onSelected: state.categoryId == null ? cubit.kindChanged : null,
        ),
        Text(l10n.categoryFormIcon, style: labelStyle),
        EntityIconPicker(
          selected: state.icon,
          color: state.color,
          onSelected: cubit.iconChanged,
        ),
        Text(l10n.categoryFormColor, style: labelStyle),
        ColorSwatchPicker(
          selected: state.color,
          onSelected: cubit.colorChanged,
        ),
        if (state.canHaveParent)
          DropdownButtonFormField<String?>(
            // Смена kind меняет список — пересоздаём поле со сброшенным значением.
            key: ValueKey((state.kind, state.parentId)),
            initialValue: state.parentId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.categoryFormParent),
            items: [
              DropdownMenuItem(child: Text(l10n.categoryFormNoParent)),
              for (final option in options)
                DropdownMenuItem(value: option.id, child: Text(option.name)),
            ],
            onChanged: cubit.parentChanged,
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: state.status == .submitting ? null : cubit.save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: state.status == .submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.commonSave),
        ),
      ],
    );
  }
}
