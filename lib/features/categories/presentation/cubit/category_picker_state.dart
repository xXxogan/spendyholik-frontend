part of 'category_picker_cubit.dart';

@freezed
sealed class CategoryPickerState with _$CategoryPickerState {
  const factory CategoryPickerState.loading() = CategoryPickerLoading;

  /// Подкатегории сразу за своим родителем.
  const factory CategoryPickerState.loaded(List<CategoryModel> categories) =
      CategoryPickerLoaded;
  const factory CategoryPickerState.error(Failure failure) =
      CategoryPickerError;
}
