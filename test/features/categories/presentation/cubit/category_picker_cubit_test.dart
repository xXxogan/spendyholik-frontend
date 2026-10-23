import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/data/repositories/repositories.dart';
import 'package:spendyholik/features/categories/presentation/cubit/category_picker_cubit.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

CategoryModel category(String id, {String? parentId}) => CategoryModel(
  id: id,
  name: id,
  kind: CategoryKind.expense,
  icon: EntityIcon.other,
  color: EntityColor.gray,
  parentId: parentId,
  transactionCount: 0,
);

void main() {
  late MockCategoryRepository repository;

  setUp(() => repository = MockCategoryRepository());

  blocTest<CategoryPickerCubit, CategoryPickerState>(
    'грузит категории нужного kind, подкатегории — сразу за родителем',
    setUp: () =>
        when(() => repository.getCategories(kind: CategoryKind.expense))
            .thenAnswer(
              (_) async => [
                category('food'),
                category('cafe'),
                category('delivery', parentId: 'food'),
              ],
            ),
    build: () => CategoryPickerCubit(repository),
    act: (cubit) => cubit.load(.expense),
    expect: () => [
      const CategoryPickerState.loading(),
      isA<CategoryPickerLoaded>().having(
        (s) => s.categories.map((c) => c.id),
        'ids',
        ['food', 'delivery', 'cafe'],
      ),
    ],
  );

  blocTest<CategoryPickerCubit, CategoryPickerState>(
    'ошибка — error',
    setUp: () =>
        when(() => repository.getCategories(kind: CategoryKind.income))
            .thenThrow(const NetworkFailure()),
    build: () => CategoryPickerCubit(repository),
    act: (cubit) => cubit.load(.income),
    expect: () => [
      const CategoryPickerState.loading(),
      const CategoryPickerState.error(NetworkFailure()),
    ],
  );
}
