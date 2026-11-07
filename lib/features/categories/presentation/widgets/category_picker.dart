import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/presentation/cubit/category_picker_cubit.dart';
import 'package:spendyholik/features/categories/presentation/widgets/category_choice.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Сетка категорий одного [kind] для форм операций и бюджетов.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.kind,
    required this.selected,
    required this.onSelected,
    this.errorText,
  });

  final CategoryKind kind;
  final String? selected;
  final ValueChanged<String> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      key: ValueKey(kind),
      create: (_) => getIt<CategoryPickerCubit>()..load(kind),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 8,
        children: [
          BlocBuilder<CategoryPickerCubit, CategoryPickerState>(
            builder: (context, state) => switch (state) {
              CategoryPickerLoading() => const SkeletonList(
                itemCount: 1,
                itemHeight: 72,
              ),
              CategoryPickerLoaded(:final categories) when categories.isEmpty =>
                Text(context.l10n.categoryPickerEmpty),
              CategoryPickerLoaded(:final categories) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in categories)
                    CategoryChoice(
                      category: category,
                      selected: category.id == selected,
                      onTap: () => onSelected(category.id),
                    ),
                ],
              ),
              CategoryPickerError(:final failure) => FailureView(
                failure: failure,
                onRetry: () => context.read<CategoryPickerCubit>().load(kind),
              ),
            },
          ),
          if (errorText case final error?)
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}
