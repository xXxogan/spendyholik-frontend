import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:spendyholik/features/debts/data/repositories/repositories.dart';
import 'package:spendyholik/features/debts/presentation/cubit/debt_form_cubit.dart';
import 'package:spendyholik/features/debts/presentation/widgets/debt_form.dart';

import '../../../../helpers/pump_app.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

void main() {
  setUp(() {
    final accounts = MockAccountRepository();
    final bus = MockDataChangeBus();
    when(() => bus.changes).thenAnswer((_) => const Stream.empty());
    when(() => accounts.getAccounts()).thenAnswer((_) async => []);
    getIt.registerFactory(() => AccountsCubit(accounts, bus));
  });

  tearDown(() => getIt.unregister<AccountsCubit>());

  Future<void> pump(WidgetTester tester, DebtFormState state) async {
    final cubit = DebtFormCubit(MockDebtRepository(), MockAccountRepository());
    await pumpPage(
      tester,
      SingleChildScrollView(
        child: DebtForm(state: state, cubit: cubit),
      ),
    );
    await settle(tester);
  }

  testWidgets('создание: есть выбор счёта и дата', (tester) async {
    await pump(tester, const DebtFormState());

    expect(find.byType(AccountPicker), findsOneWidget);
    expect(find.text('Дата'), findsOneWidget);
    expect(find.text('Сегодня'), findsOneWidget);
  });

  testWidgets('создание со счётом: есть кнопка «Без счёта»', (tester) async {
    await pump(tester, const DebtFormState(accountId: 'a1'));

    expect(find.text('Без счёта'), findsOneWidget);
  });

  testWidgets('правка: нет ни счёта, ни даты', (tester) async {
    await pump(tester, const DebtFormState(debtId: 'd1'));

    expect(find.byType(AccountPicker), findsNothing);
    expect(find.text('Дата'), findsNothing);
  });
}
