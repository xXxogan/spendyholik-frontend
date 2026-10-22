import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:spendyholik/features/categories/presentation/pages/categories_page.dart';

import '../../../../helpers/pump_app.dart';

class MockCategoriesCubit extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

CategoryModel category(
  String id,
  String name,
  CategoryKind kind, {
  String? parentId,
  int count = 0,
}) => CategoryModel(
  id: id,
  name: name,
  kind: kind,
  icon: EntityIcon.other,
  color: EntityColor.gray,
  parentId: parentId,
  transactionCount: count,
);

void main() {
  late MockCategoriesCubit cubit;

  final groups = {
    CategoryKind.expense: [
      CategoryNode(
        category: category('groceries', 'Продукты', .expense, count: 32),
        children: [
          category(
            'delivery',
            'Доставка',
            .expense,
            parentId: 'groceries',
            count: 5,
          ),
        ],
      ),
    ],
    CategoryKind.income: [
      CategoryNode(
        category: category('salary', 'Зарплата', .income, count: 3),
        children: const [],
      ),
    ],
    CategoryKind.transfer: const <CategoryNode>[],
  };

  setUp(() => cubit = MockCategoriesCubit());

  Future<void> pump(WidgetTester tester, CategoriesState state) async {
    when(() => cubit.state).thenReturn(state);
    await pumpPage(
      tester,
      BlocProvider<CategoriesCubit>.value(
        value: cubit,
        child: const CategoriesView(),
      ),
    );
    await settle(tester);
  }

  testWidgets('расходы раскрыты: категория, подкатегория и счётчики', (
    tester,
  ) async {
    await pump(tester, CategoriesState.loaded(groups));

    expect(find.text('Расходы'), findsOneWidget);
    expect(find.text('Продукты'), findsOneWidget);
    expect(find.text('Доставка'), findsOneWidget);
    expect(find.text('32 операции'), findsOneWidget);
    expect(find.text('5 операций'), findsOneWidget);
  });

  testWidgets('доходы свёрнуты и раскрываются по тапу', (tester) async {
    await pump(tester, CategoriesState.loaded(groups));
    expect(find.text('Зарплата'), findsNothing);

    await tester.tap(find.text('Доходы'));
    await settle(tester);

    expect(find.text('Зарплата'), findsOneWidget);
  });

  testWidgets('тап по раскрытой группе сворачивает её', (tester) async {
    await pump(tester, CategoriesState.loaded(groups));

    await tester.tap(find.text('Расходы'));
    await settle(tester);

    expect(find.text('Продукты'), findsNothing);
  });

  testWidgets('ошибка — «Повторить» вызывает load', (tester) async {
    when(() => cubit.load()).thenAnswer((_) async {});
    await pump(tester, const CategoriesState.error(NetworkFailure()));

    await tester.tap(find.text('Повторить'));

    verify(() => cubit.load()).called(1);
  });
}
