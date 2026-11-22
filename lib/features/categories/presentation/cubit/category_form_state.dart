part of 'category_form_cubit.dart';

enum CategoryField { name }

@freezed
abstract class CategoryFormState with _$CategoryFormState {
  const factory CategoryFormState({
    String? categoryId,
    @Default('') String name,
    @Default(CategoryKind.expense) CategoryKind kind,
    @Default(EntityIcon.other) EntityIcon icon,
    @Default(EntityColor.pink) EntityColor color,
    @Default(true) bool sendIcon,
    @Default(true) bool sendColor,
    String? parentId,

    /// Все категории: из них собираются варианты родителя.
    @Default([]) List<CategoryModel> categories,
    @Default(false) bool isLoading,
    @Default(FormStatus.idle) FormStatus status,
    @Default({}) Map<CategoryField, FieldError> fieldErrors,
    Failure? failure,
  }) = _CategoryFormState;

  const CategoryFormState._();

  /// Форма не загрузилась — вместо неё ошибка и «Повторить».
  bool get loadFailed => failure != null && status == FormStatus.idle;

  /// Один уровень вложенности: у категории с подкатегориями родителя быть не может.
  bool get canHaveParent =>
      categoryId == null || !categories.any((c) => c.parentId == categoryId);

  List<CategoryModel> get parentOptions => [
    for (final category in categories)
      if (category.kind == kind &&
          category.parentId == null &&
          category.id != categoryId)
        category,
  ];
}
