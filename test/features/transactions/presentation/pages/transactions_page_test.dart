import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/categories/categories.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:spendyholik/features/transactions/presentation/pages/transactions_page.dart';

import '../../../../helpers/pump_app.dart';

class MockTransactionsCubit extends MockCubit<TransactionsState>
    implements TransactionsCubit {}

void main() {
  late MockTransactionsCubit cubit;

  const card = AccountRef(id: 'card', name: 'Карта', color: EntityColor.blue);
  const cash = AccountRef(
    id: 'cash',
    name: 'Наличные',
    color: EntityColor.teal,
  );
  const food = CategoryRef(
    id: 'food',
    name: 'Продукты',
    icon: EntityIcon.cart,
    color: EntityColor.green,
  );
  const salary = CategoryRef(
    id: 'salary',
    name: 'Зарплата',
    icon: EntityIcon.salary,
    color: EntityColor.green,
  );

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);

  final groups = [
    TransactionDayGroup(
      day: today,
      items: [
        TransactionModel(
          id: 'shop',
          type: .expense,
          amount: 124000,
          title: 'Пятёрочка',
          category: food,
          account: card,
          occurredAt: today.add(const Duration(hours: 1)),
        ),
      ],
    ),
    TransactionDayGroup(
      day: yesterday,
      items: [
        TransactionModel(
          id: 'pay',
          type: .income,
          amount: 11850000,
          title: '',
          category: salary,
          account: card,
          occurredAt: yesterday.add(const Duration(hours: 9)),
        ),
        TransactionModel(
          id: 'move',
          type: .transfer,
          amount: 500000,
          title: 'Снял наличные',
          account: card,
          toAccount: cash,
          occurredAt: yesterday.add(const Duration(hours: 8)),
        ),
      ],
    ),
  ];

  setUpAll(() => registerFallbackValue(const TransactionFilter()));

  setUp(() => cubit = MockTransactionsCubit());

  Future<void> pump(WidgetTester tester, TransactionsState state) async {
    when(() => cubit.state).thenReturn(state);
    await pumpPage(
      tester,
      BlocProvider<TransactionsCubit>.value(
        value: cubit,
        child: const TransactionsView(),
      ),
    );
    await settle(tester);
  }

  testWidgets('заголовки дней «Сегодня» и «Вчера»', (tester) async {
    await pump(
      tester,
      TransactionsState.loaded(groups, const TransactionFilter()),
    );

    expect(find.text('Сегодня'), findsOneWidget);
    expect(find.text('Вчера'), findsOneWidget);
  });

  testWidgets(
    'расход с минусом и красным, доход с плюсом и зелёным, перевод без знака',
    (tester) async {
      await pump(
        tester,
        TransactionsState.loaded(groups, const TransactionFilter()),
      );

      Color? colorOf(String text) =>
          tester.widget<Text>(find.text(text)).style?.color;
      expect(
        colorOf('−1\u00a0240\u00a0₽'),
        AppColors.negative(Brightness.light),
      );
      expect(
        colorOf('+118\u00a0500\u00a0₽'),
        AppColors.positive(Brightness.light),
      );
      expect(find.text('5\u00a0000\u00a0₽'), findsOneWidget);
    },
  );

  testWidgets('пустой заголовок — имя категории; перевод — откуда и куда', (
    tester,
  ) async {
    await pump(
      tester,
      TransactionsState.loaded(groups, const TransactionFilter()),
    );

    expect(find.text('Зарплата'), findsOneWidget);
    expect(find.text('Карта → Наличные'), findsOneWidget);
  });

  testWidgets('чип «Доходы» вызывает setType(income)', (tester) async {
    when(() => cubit.setType(any())).thenAnswer((_) async {});
    await pump(
      tester,
      TransactionsState.loaded(groups, const TransactionFilter()),
    );

    await tester.tap(find.text('Доходы'));

    verify(() => cubit.setType(TransactionType.income)).called(1);
  });

  testWidgets('пусто — «Ничего не найдено», «Сбросить» снимает фильтр', (
    tester,
  ) async {
    when(() => cubit.applyFilter(any())).thenAnswer((_) async {});
    await pump(
      tester,
      const TransactionsState.empty(TransactionFilter(type: .transfer)),
    );

    expect(find.text('Ничего не найдено'), findsOneWidget);
    await tester.tap(find.text('Сбросить'));

    verify(() => cubit.applyFilter(const TransactionFilter())).called(1);
  });

  testWidgets('ошибка — «Повторить» перезагружает', (tester) async {
    when(() => cubit.load(any())).thenAnswer((_) async {});
    await pump(tester, const TransactionsState.error(NetworkFailure()));

    await tester.tap(find.text('Повторить'));

    verify(() => cubit.load(any())).called(1);
  });

  testWidgets('без фильтра сверх типа — кнопка «Фильтры» без точки', (
    tester,
  ) async {
    await pump(
      tester,
      TransactionsState.loaded(groups, const TransactionFilter(type: .income)),
    );

    expect(find.byTooltip('Фильтры'), findsOneWidget);
    expect(find.byType(Badge), findsNothing);
  });

  testWidgets('фильтр по счёту — точка на кнопке «Фильтры»', (tester) async {
    await pump(
      tester,
      TransactionsState.loaded(
        groups,
        const TransactionFilter(accountId: 'card'),
      ),
    );

    expect(find.byType(Badge), findsOneWidget);
  });
}
