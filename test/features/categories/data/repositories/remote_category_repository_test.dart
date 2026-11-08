import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/categories/data/api/categories_api.dart';
import 'package:spendyholik/features/categories/data/models/category_dtos.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/data/repositories/remote_category_repository.dart';
import 'package:talker/talker.dart';

import '../../../../helpers/dio_errors.dart';

class MockCategoriesApi extends Mock implements CategoriesApi {}

class MockApiCache extends Mock implements ApiCache {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

/// Копия примера `CategoryOut` из схемы API.
CategoryOutDto category({
  String id = 'c1',
  String type = 'expense',
  String icon = 'cart',
  String color = 'green',
  String? parentId,
  int count = 3,
}) => CategoryOutDto.fromJson({
  'id': id,
  'name': 'Продукты',
  'type': type,
  'icon': icon,
  'color': color,
  'parent_id': parentId,
  'is_system': false,
  'transaction_count': count,
});

const draft = CategoryDraft(
  name: 'Кофе',
  kind: CategoryKind.expense,
  icon: EntityIcon.cafe,
  color: EntityColor.orange,
  parentId: 'p1',
);

void main() {
  late MockCategoriesApi api;
  late MockApiCache cache;
  late MockDataChangeBus bus;
  late RemoteCategoryRepository repository;

  setUpAll(() {
    registerFallbackValue(<DataTopic>{});
    registerFallbackValue(
      const CategoryCreateBody(name: '', type: '', icon: '', color: ''),
    );
    registerFallbackValue(
      const CategoryPatchBody(name: '', icon: '', color: ''),
    );
  });

  setUp(() {
    api = MockCategoriesApi();
    cache = MockApiCache();
    bus = MockDataChangeBus();
    when(() => cache.read(any())).thenAnswer((_) async => null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    repository = RemoteCategoryRepository(
      api,
      CachedReader(cache, NetworkStatus(), Talker()),
      bus,
    );
  });

  group('getCategories', () {
    test('маппинг CategoryOut', () async {
      when(() => api.list()).thenAnswer(
        (_) async => [
          category(type: 'income', parentId: 'p1', count: 7),
          category(id: 'c2', icon: 'weird', color: 'weird'),
        ],
      );

      final result = await repository.getCategories();

      expect(result[0].kind, CategoryKind.income);
      expect(result[0].parentId, 'p1');
      expect(result[0].transactionCount, 7);
      expect(result[0].icon, EntityIcon.cart);
      expect(result[0].color, EntityColor.green);
      expect(result[1].icon, EntityIcon.other);
      expect(result[1].color, EntityColor.gray);
    });

    test('kind: expense отбрасывает доходы на клиенте', () async {
      when(() => api.list()).thenAnswer(
        (_) async => [category(), category(id: 'c2', type: 'income')],
      );

      final result = await repository.getCategories(kind: .expense);

      expect(result.map((c) => c.id), ['c1']);
    });
  });

  group('записи', () {
    test('create — тело с icon.name, color.name, parent_id; emit', () async {
      when(() => api.create(any())).thenAnswer((_) async => category());

      await repository.create(draft);

      final body =
          verify(() => api.create(captureAny())).captured.single
              as CategoryCreateBody;
      expect(body.toJson(), {
        'name': 'Кофе',
        'type': 'expense',
        'icon': 'cafe',
        'color': 'orange',
        'parent_id': 'p1',
      });
      verify(() => bus.emit({DataTopic.categories})).called(1);
    });

    test('update — PATCH и emit зависимых тем', () async {
      when(() => api.update('c1', any())).thenAnswer((_) async => category());

      await repository.update('c1', draft);

      verify(
        () => bus.emit({
          DataTopic.categories,
          DataTopic.transactions,
          DataTopic.budgets,
          DataTopic.recurring,
        }),
      ).called(1);
    });

    test('422 name — ValidationFailure у поля name, без emit', () async {
      when(() => api.create(any()))
          .thenThrow(apiError(422, 'validation_error', {'name': 'required'}));

      await expectLater(
        repository.create(draft),
        throwsA(
          isA<ValidationFailure>().having((f) => f.field, 'field', 'name'),
        ),
      );
      verifyNever(() => bus.emit(any()));
    });
  });
}
