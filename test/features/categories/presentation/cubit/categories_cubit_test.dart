import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/data/repositories/repositories.dart';
import 'package:spendyholik/features/categories/presentation/cubit/categories_cubit.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

CategoryModel category(
  String id,
  CategoryKind kind, {
  String? parentId,
  int count = 0,
}) => CategoryModel(
  id: id,
  name: id,
  kind: kind,
  icon: EntityIcon.other,
  color: EntityColor.gray,
  parentId: parentId,
  transactionCount: count,
);

void main() {
  late MockCategoryRepository repository;
  late MockDataChangeBus bus;
  late StreamController<Set<DataTopic>> changes;

  final groceries = category('groceries', .expense);
  final delivery = category('delivery', .expense, parentId: 'groceries');
  final cafe = category('cafe', .expense);
  final salary = category('salary', .income);

  setUp(() {
    repository = MockCategoryRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  CategoriesCubit build() => CategoriesCubit(repository, bus);

  Map<CategoryKind, List<CategoryNode>> groupsOf(CategoriesState state) =>
      (state as CategoriesLoaded).groups;

  blocTest<CategoriesCubit, CategoriesState>(
    'группы по kind, подкатегории под родителем, порядок сохранён',
    setUp: () =>
        when(() => repository.getCategories())
            .thenAnswer((_) async => [delivery, groceries, salary, cafe]),
    build: build,
    act: (cubit) => cubit.load(),
    skip: 1,
    expect: () => [isA<CategoriesLoaded>()],
    verify: (cubit) {
      final groups = groupsOf(cubit.state);
      expect(groups.keys, CategoryKind.values);
      final expense = groups[CategoryKind.expense]!;
      expect(expense.map((n) => n.category.id), ['groceries', 'cafe']);
      expect(expense.first.children.map((c) => c.id), ['delivery']);
      expect(expense.last.children, isEmpty);
      expect(groups[CategoryKind.income]!.single.category.id, 'salary');
      expect(groups[CategoryKind.transfer], isEmpty);
    },
  );

  blocTest<CategoriesCubit, CategoriesState>(
    'подкатегория без родителя в списке — не теряется, становится верхним уровнем',
    setUp: () =>
        when(() => repository.getCategories())
            .thenAnswer((_) async => [delivery]),
    build: build,
    act: (cubit) => cubit.load(),
    skip: 1,
    expect: () => [isA<CategoriesLoaded>()],
    verify: (cubit) => expect(
      groupsOf(cubit.state)[CategoryKind.expense]!.single.category.id,
      'delivery',
    ),
  );

  blocTest<CategoriesCubit, CategoriesState>(
    'ошибка репозитория — error',
    setUp: () =>
        when(() => repository.getCategories())
            .thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const CategoriesState.loading(),
      const CategoriesState.error(NetworkFailure()),
    ],
  );

  blocTest<CategoriesCubit, CategoriesState>(
    'изменились операции — тихая перезагрузка без loading',
    setUp: () =>
        when(() => repository.getCategories())
            .thenAnswer((_) async => [groceries]),
    build: build,
    act: (cubit) async {
      await cubit.load();
      changes.add({DataTopic.transactions});
      await Future<void>.delayed(Duration.zero);
    },
    skip: 2,
    expect: () => [isA<CategoriesLoaded>()],
    verify: (_) => verify(() => repository.getCategories()).called(2),
  );
}
