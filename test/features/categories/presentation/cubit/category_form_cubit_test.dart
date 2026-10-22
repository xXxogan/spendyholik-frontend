import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/data/repositories/category_repository.dart';
import 'package:spendyholik/features/categories/presentation/cubit/category_form_cubit.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockCategoryRepository repository;

  const food = CategoryModel(
    id: 'food',
    name: 'Еда',
    kind: CategoryKind.expense,
    icon: EntityIcon.cart,
    color: EntityColor.green,
    transactionCount: 3,
  );
  const cafe = CategoryModel(
    id: 'cafe',
    name: 'Кафе',
    kind: CategoryKind.expense,
    icon: EntityIcon.cafe,
    color: EntityColor.orange,
    parentId: 'food',
    transactionCount: 1,
  );
  const transport = CategoryModel(
    id: 'transport',
    name: 'Транспорт',
    kind: CategoryKind.expense,
    icon: EntityIcon.bus,
    color: EntityColor.blue,
    transactionCount: 0,
  );
  const salary = CategoryModel(
    id: 'salary',
    name: 'Зарплата',
    kind: CategoryKind.income,
    icon: EntityIcon.salary,
    color: EntityColor.green,
    transactionCount: 2,
  );
  const all = [food, cafe, transport, salary];

  setUpAll(
    () => registerFallbackValue(
      const CategoryDraft(
        name: '',
        kind: CategoryKind.expense,
        icon: EntityIcon.other,
        color: EntityColor.pink,
      ),
    ),
  );

  setUp(() {
    repository = MockCategoryRepository();
    when(() => repository.getCategories()).thenAnswer((_) async => all);
  });

  CategoryFormCubit build() => CategoryFormCubit(repository);

  Future<CategoryFormCubit> initialized([String? id]) async {
    final cubit = build();
    await cubit.init(id);
    return cubit;
  }

  test('init без id — пустая форма и список категорий', () async {
    final cubit = await initialized();

    expect(cubit.state.categoryId, isNull);
    expect(cubit.state.name, '');
    expect(cubit.state.categories, all);
    expect(cubit.state.isLoading, isFalse);
  });

  test('init(id) заполняет поля', () async {
    final cubit = await initialized('cafe');

    expect(cubit.state.categoryId, 'cafe');
    expect(cubit.state.name, 'Кафе');
    expect(cubit.state.icon, EntityIcon.cafe);
    expect(cubit.state.color, EntityColor.orange);
    expect(cubit.state.parentId, 'food');
  });

  test('init(id) неизвестного — failure, loadFailed', () async {
    final cubit = await initialized('nope');

    expect(cubit.state.failure, isA<NotFoundFailure>());
    expect(cubit.state.loadFailed, isTrue);
  });

  test('init: ошибка загрузки списка — loadFailed', () async {
    when(() => repository.getCategories()).thenThrow(const NetworkFailure());
    final cubit = await initialized();

    expect(cubit.state.loadFailed, isTrue);
  });

  test('родители: тот же kind, верхний уровень, не сама категория', () async {
    expect((await initialized('transport')).state.parentOptions, [food]);

    final created = await initialized();
    created.kindChanged(CategoryKind.income);
    expect(created.state.parentOptions, [salary]);
  });

  test('у категории с подкатегориями родителя быть не может', () async {
    final cubit = await initialized('food');

    expect(cubit.state.canHaveParent, isFalse);
    expect((await initialized('transport')).state.canHaveParent, isTrue);
  });

  test('смена kind сбрасывает родителя', () async {
    final cubit = await initialized();
    cubit.parentChanged('food');

    cubit.kindChanged(CategoryKind.income);

    expect(cubit.state.parentId, isNull);
  });

  test('тот же kind родителя не сбрасывает', () async {
    final cubit = await initialized();
    cubit.parentChanged('food');

    cubit.kindChanged(CategoryKind.expense);

    expect(cubit.state.parentId, 'food');
  });

  test('пустое имя — required, create не вызывается', () async {
    final cubit = await initialized();

    cubit.nameChanged('   ');
    await cubit.save();

    expect(cubit.state.fieldErrors, {CategoryField.name: FieldError.required});
    expect(cubit.state.status, FormStatus.idle);
    verifyNever(() => repository.create(any()));
  });

  test('правка имени снимает его ошибку', () async {
    final cubit = await initialized();
    await cubit.save();

    cubit.nameChanged('Х');

    expect(cubit.state.fieldErrors, isEmpty);
  });

  blocTest<CategoryFormCubit, CategoryFormState>(
    'валидная форма: submitting → success, create с черновиком',
    build: build,
    setUp: () =>
        when(() => repository.create(any())).thenAnswer((_) async => food),
    act: (cubit) async {
      await cubit.init(null);
      cubit
        ..nameChanged('  Спорт ')
        ..iconChanged(EntityIcon.health)
        ..colorChanged(EntityColor.red)
        ..parentChanged('food');
      await cubit.save();
    },
    skip: 6,
    expect: () => [
      isA<CategoryFormState>().having(
        (s) => s.status,
        'status',
        FormStatus.submitting,
      ),
      isA<CategoryFormState>().having(
        (s) => s.status,
        'status',
        FormStatus.success,
      ),
    ],
    verify: (_) {
      final draft =
          verify(() => repository.create(captureAny())).captured.single
              as CategoryDraft;
      expect(draft.name, 'Спорт');
      expect(draft.kind, CategoryKind.expense);
      expect(draft.icon, EntityIcon.health);
      expect(draft.color, EntityColor.red);
      expect(draft.parentId, 'food');
    },
  );

  test('с id вызывается update', () async {
    when(() => repository.update(any(), any())).thenAnswer((_) async => cafe);
    final cubit = await initialized('cafe');

    await cubit.save();

    verify(() => repository.update('cafe', any())).called(1);
    verifyNever(() => repository.create(any()));
    expect(cubit.state.status, FormStatus.success);
  });

  test('ошибка репозитория — failure, поля сохранены', () async {
    when(() => repository.create(any())).thenThrow(const NetworkFailure());
    final cubit = await initialized();
    cubit.nameChanged('Спорт');

    await cubit.save();

    expect(cubit.state.status, FormStatus.failure);
    expect(cubit.state.failure, isA<NetworkFailure>());
    expect(cubit.state.name, 'Спорт');
    expect(cubit.state.loadFailed, isFalse);
  });

  blocTest<CategoryFormCubit, CategoryFormState>(
    'правка — тип не меняется: операции и подкатегории остаются того же типа',
    build: build,
    act: (cubit) async {
      await cubit.init('transport');
      cubit.kindChanged(CategoryKind.income);
    },
    skip: 2,
    expect: () => <CategoryFormState>[],
  );
}
