import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/quick_add_cubit.dart';
import 'package:spendyholik/features/transactions/presentation/widgets/quick_add_sheet.dart';

import '../../../../helpers/pump_app.dart';

class MockQuickAddCubit extends MockCubit<QuickAddState>
    implements QuickAddCubit {}

void main() {
  late MockQuickAddCubit cubit;

  const food = CategoryModel(
    id: 'food',
    name: 'Продукты',
    kind: CategoryKind.expense,
    icon: EntityIcon.cart,
    color: EntityColor.green,
    transactionCount: 32,
  );

  setUpAll(() => registerFallbackValue(TransactionType.expense));

  setUp(() => cubit = MockQuickAddCubit());

  Future<void> pump(WidgetTester tester, QuickAddState state) async {
    when(() => cubit.state).thenReturn(state);
    await pumpPage(
      tester,
      Material(
        child: BlocProvider<QuickAddCubit>.value(
          value: cubit,
          child: const QuickAddView(),
        ),
      ),
    );
    await settle(tester);
  }

  const ready = QuickAddState(categories: [food], isLoading: false);

  testWidgets('категории чипами, тап выбирает', (tester) async {
    await pump(tester, ready);

    await tester.tap(find.text('Продукты'));

    verify(() => cubit.categoryChanged('food')).called(1);
  });

  testWidgets('суффикс суммы — валюта счёта', (tester) async {
    await pump(tester, ready.copyWith(accountCurrency: Currency.usd));

    expect(find.text(r'$'), findsOneWidget);
  });

  testWidgets('«Доход» меняет тип', (tester) async {
    when(() => cubit.typeChanged(any())).thenAnswer((_) async {});
    await pump(tester, ready);

    await tester.tap(find.text('Доход'));

    verify(() => cubit.typeChanged(TransactionType.income)).called(1);
  });

  testWidgets('«Добавить» вызывает submit', (tester) async {
    when(() => cubit.submit()).thenAnswer((_) async {});
    await pump(tester, ready);

    await tester.tap(find.text('Добавить'));

    verify(() => cubit.submit()).called(1);
  });

  testWidgets('нет дебетовой карты — понятный текст', (tester) async {
    await pump(
      tester,
      ready.copyWith(
        status: FormStatus.failure,
        fieldErrors: {QuickAddField.account: FieldError.required},
      ),
    );

    expect(find.text('Нет активной дебетовой карты'), findsOneWidget);
  });
}
