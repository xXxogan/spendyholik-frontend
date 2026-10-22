import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/data/repositories/category_repository.dart';

@LazySingleton(as: CategoryRepository)
class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository(this._backend, this._bus);

  final FakeBackend _backend;
  final DataChangeBus _bus;

  @override
  Future<List<CategoryModel>> getCategories({CategoryKind? kind}) => _backend(
    () => _backend.categories
        .where((category) => kind == null || category.kind == kind)
        .toList(),
  );

  @override
  Future<CategoryModel> create(CategoryDraft draft) async {
    final created = await _backend(() => _backend.addCategory(draft));
    _bus.emit({DataTopic.categories});
    return created;
  }

  @override
  Future<CategoryModel> update(String id, CategoryDraft draft) async {
    final updated = await _backend(() {
      _find(id);
      _backend.updateCategory(id, draft);
      return _find(id);
    });
    // Имя и иконка категории видны в списке операций.
    _bus.emit({DataTopic.categories, DataTopic.transactions});
    return updated;
  }

  CategoryModel _find(String id) => _backend.categories.firstWhere(
    (category) => category.id == id,
    orElse: () => throw const NotFoundFailure(),
  );
}
