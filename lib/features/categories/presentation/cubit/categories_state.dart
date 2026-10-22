part of 'categories_cubit.dart';

@freezed
sealed class CategoriesState with _$CategoriesState {
  const factory CategoriesState.loading() = CategoriesLoading;

  /// Все [CategoryKind] есть в карте, пустые группы — пустым списком.
  const factory CategoriesState.loaded(
    Map<CategoryKind, List<CategoryNode>> groups,
  ) = CategoriesLoaded;
  const factory CategoriesState.error(Failure failure) = CategoriesError;
}
