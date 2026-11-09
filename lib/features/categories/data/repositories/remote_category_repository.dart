import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/api_call.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/features/categories/data/api/categories_api.dart';
import 'package:spendyholik/features/categories/data/models/category_dtos.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/data/repositories/category_repository.dart';

@LazySingleton(as: CategoryRepository)
class RemoteCategoryRepository implements CategoryRepository {
  RemoteCategoryRepository(this._api, this._reader, this._bus);

  static const _fields = {'name': 'name', 'parent_id': 'parentId'};

  final CategoriesApi _api;
  final CachedReader _reader;
  final DataChangeBus _bus;

  @override
  Future<List<CategoryModel>> getCategories({CategoryKind? kind}) async {
    final dtos = await _reader.read(
      key: cacheKey('categories'),
      fetch: () => _call(_api.list),
      toJson: (list) => [for (final dto in list) dto.toJson()],
      fromJson: (json) => [
        for (final item in json! as List)
          CategoryOutDto.fromJson(item as Map<String, dynamic>),
      ],
    );
    // Фильтр на клиенте: в кэше один общий список.
    return [
      for (final dto in dtos)
        if (kind == null || _kind(dto.type) == kind) _category(dto),
    ];
  }

  @override
  Future<CategoryModel> create(CategoryDraft draft) async {
    final created = await _call(
      () => _api.create(
        CategoryCreateBody(
          name: draft.name,
          type: draft.kind.name,
          icon: draft.icon.name,
          color: draft.color.name,
          parentId: draft.parentId,
        ),
      ),
    );
    _bus.emit({DataTopic.categories});
    return _category(created);
  }

  @override
  Future<CategoryModel> update(String id, CategoryDraft draft) async {
    final updated = await _call(
      () => _api.update(
        id,
        CategoryPatchBody(
          name: draft.name,
          icon: draft.icon.name,
          color: draft.color.name,
          parentId: draft.parentId,
        ),
      ),
    );
    // Имя и иконка категории видны в операциях, бюджетах и шаблонах.
    _bus.emit({
      DataTopic.categories,
      DataTopic.transactions,
      DataTopic.budgets,
      DataTopic.recurring,
    });
    return _category(updated);
  }

  static CategoryKind _kind(String type) =>
      CategoryKind.values.asNameMap()[type] ?? CategoryKind.expense;

  CategoryModel _category(CategoryOutDto dto) => CategoryModel(
    id: dto.id,
    name: dto.name,
    kind: _kind(dto.type),
    icon: EntityIcon.values.asNameMap()[dto.icon] ?? EntityIcon.other,
    color: EntityColor.values.asNameMap()[dto.color] ?? EntityColor.gray,
    parentId: dto.parentId,
    transactionCount: dto.transactionCount,
  );

  Future<T> _call<T>(Future<T> Function() request) =>
      callApi(request, fields: _fields);
}
