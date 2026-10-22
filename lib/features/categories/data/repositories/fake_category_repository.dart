import 'package:injectable/injectable.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/data/repositories/category_repository.dart';

@LazySingleton(as: CategoryRepository)
class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository(this._backend);

  final FakeBackend _backend;

  @override
  Future<List<CategoryModel>> getCategories({CategoryKind? kind}) => _backend(
    () => _backend.categories
        .where((category) => kind == null || category.kind == kind)
        .toList(),
  );

  @override
  Future<CategoryModel> create(CategoryDraft draft) =>
      throw UnimplementedError();

  @override
  Future<CategoryModel> update(String id, CategoryDraft draft) =>
      throw UnimplementedError();
}
