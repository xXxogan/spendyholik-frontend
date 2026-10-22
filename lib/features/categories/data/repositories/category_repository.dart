import 'package:spendyholik/features/categories/data/models/models.dart';

/// Все методы бросают только [Failure] из `core/errors`.
abstract interface class CategoryRepository {
  /// [CategoryModel.transactionCount] — только свои операции, без подкатегорий.
  Future<List<CategoryModel>> getCategories({CategoryKind? kind});

  Future<CategoryModel> create(CategoryDraft draft);

  Future<CategoryModel> update(String id, CategoryDraft draft);
}
