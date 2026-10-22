import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/presentation/cubit/category_form_cubit.dart';
import 'package:spendyholik/features/categories/presentation/pages/category_edit_page.dart';

import '../../../../helpers/pump_app.dart';

class MockCategoryFormCubit extends MockCubit<CategoryFormState>
    implements CategoryFormCubit {}

void main() {
  late MockCategoryFormCubit cubit;

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

  setUpAll(() => registerFallbackValue(CategoryKind.expense));

  setUp(() => cubit = MockCategoryFormCubit());

  Future<void> pump(WidgetTester tester, CategoryFormState state) async {
    when(() => cubit.state).thenReturn(state);
    await pumpPage(
      tester,
      BlocProvider<CategoryFormCubit>.value(
        value: cubit,
        child: const CategoryEditView(),
      ),
    );
    await settle(tester);
  }

  testWidgets('новая категория — заголовок', (tester) async {
    await pump(tester, const CategoryFormState());

    expect(find.text('Новая категория'), findsWidgets);
  });

  testWidgets('правка — заголовок', (tester) async {
    await pump(
      tester,
      const CategoryFormState(categoryId: 'cafe', categories: [food, cafe]),
    );

    expect(find.text('Изменить категорию'), findsWidgets);
  });

  testWidgets('«Сохранить» вызывает save', (tester) async {
    when(() => cubit.save()).thenAnswer((_) async {});
    await pump(tester, const CategoryFormState());

    await tester.ensureVisible(find.text('Сохранить'));
    await tester.tap(find.text('Сохранить'));

    verify(() => cubit.save()).called(1);
  });

  testWidgets('ошибка required — текст у поля', (tester) async {
    await pump(
      tester,
      const CategoryFormState(
        fieldErrors: {CategoryField.name: FieldError.required},
      ),
    );

    expect(find.text('Обязательное поле'), findsOneWidget);
  });

  testWidgets('у категории с подкатегориями поля родителя нет', (tester) async {
    await pump(
      tester,
      const CategoryFormState(categoryId: 'food', categories: [food, cafe]),
    );

    expect(find.text('Родительская категория'), findsNothing);
  });

  testWidgets('у обычной категории поле родителя есть', (tester) async {
    await pump(tester, const CategoryFormState(categories: [food]));

    expect(find.text('Родительская категория'), findsOneWidget);
  });

  testWidgets('не загрузилась — ошибка и «Повторить»', (tester) async {
    when(() => cubit.init('x')).thenAnswer((_) async {});
    await pump(
      tester,
      const CategoryFormState(categoryId: 'x', failure: NotFoundFailure()),
    );

    expect(find.text('Сохранить'), findsNothing);
    await tester.tap(find.text('Повторить'));

    verify(() => cubit.init('x')).called(1);
  });

  testWidgets('правка — чипы типа неактивны', (tester) async {
    await pump(
      tester,
      const CategoryFormState(categoryId: 'food', categories: [food, cafe]),
    );

    await tester.tap(find.text('Доходы'));

    verifyNever(() => cubit.kindChanged(any()));
  });

  testWidgets('новая — выбор типа вызывает kindChanged', (tester) async {
    await pump(tester, const CategoryFormState());

    await tester.tap(find.text('Доходы'));

    verify(() => cubit.kindChanged(CategoryKind.income)).called(1);
  });
}
