import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/entity_color.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/data/models/account_model.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:spendyholik/features/accounts/presentation/pages/accounts_page.dart';

import '../../../../helpers/pump_app.dart';

class MockAccountsCubit extends MockCubit<AccountsState>
    implements AccountsCubit {}

void main() {
  late MockAccountsCubit cubit;

  const card = AccountModel(
    id: 'card',
    name: 'Карта Тинькофф',
    type: AccountType.debit,
    balance: 8425000,
    color: EntityColor.blue,
    isArchived: false,
    cardLast4: '4831',
  );
  const credit = AccountModel(
    id: 'credit',
    name: 'Кредитка',
    type: AccountType.credit,
    balance: -2340000,
    color: EntityColor.red,
    isArchived: false,
  );

  setUp(() => cubit = MockAccountsCubit());

  Future<void> pump(
    WidgetTester tester,
    AccountsState state, {
    double width = 400,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpPage(
      tester,
      BlocProvider<AccountsCubit>.value(
        value: cubit,
        child: const AccountsView(),
      ),
      width: width,
    );
    await settle(tester);
  }

  testWidgets('loading — скелетон', (tester) async {
    await pump(tester, const AccountsState.loading());

    expect(find.byType(SkeletonList), findsOneWidget);
  });

  testWidgets('loaded — имена, маска карты и суммы со знаком', (tester) async {
    await pump(
      tester,
      const AccountsState.loaded([card, credit], AccountsFilter.all),
    );

    expect(find.text('Карта Тинькофф'), findsOneWidget);
    expect(find.textContaining('4831'), findsOneWidget);
    expect(find.text('84 250 ₽'), findsOneWidget);
    expect(find.text('−23 400 ₽'), findsOneWidget);
  });

  testWidgets('нажатие на чип фильтра вызывает setFilter', (tester) async {
    await pump(tester, const AccountsState.loaded([card], AccountsFilter.all));

    await tester.tap(find.text('Архив'));

    verify(() => cubit.setFilter(AccountsFilter.archived)).called(1);
  });

  testWidgets('empty — подсказка «Нет счетов»', (tester) async {
    await pump(tester, const AccountsState.empty(AccountsFilter.archived));

    expect(find.text('Нет счетов'), findsOneWidget);
  });

  testWidgets('error — текст ошибки, «Повторить» перезагружает', (
    tester,
  ) async {
    when(() => cubit.load()).thenAnswer((_) async {});
    await pump(tester, const AccountsState.error(NetworkFailure()));

    expect(find.text('Нет соединения'), findsOneWidget);
    await tester.tap(find.text('Повторить'));

    verify(() => cubit.load()).called(1);
  });

  testWidgets('широкий экран — счета в две колонки', (tester) async {
    await pump(
      tester,
      const AccountsState.loaded([card, credit], AccountsFilter.all),
      width: 1280,
    );

    final cardTop = tester.getTopLeft(find.text('Карта Тинькофф')).dy;
    final creditTop = tester.getTopLeft(find.text('Кредитка')).dy;
    expect(cardTop, creditTop);
  });
}
