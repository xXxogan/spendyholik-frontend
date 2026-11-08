import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/repositories.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:spendyholik/features/categories/data/repositories/repositories.dart';
import 'package:spendyholik/features/categories/presentation/cubit/category_picker_cubit.dart';
import 'package:spendyholik/features/recurring/presentation/cubit/recurring_form_cubit.dart';
import 'package:spendyholik/features/recurring/presentation/pages/recurring_edit_page.dart';
import 'package:spendyholik/features/transactions/transactions.dart';

import '../../../../helpers/pump_app.dart';

class MockRecurringFormCubit extends MockCubit<RecurringFormState>
    implements RecurringFormCubit {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

void main() {
  late MockRecurringFormCubit cubit;

  setUp(() {
    cubit = MockRecurringFormCubit();
    final categories = MockCategoryRepository();
    final accounts = MockAccountRepository();
    final bus = MockDataChangeBus();
    when(() => bus.changes).thenAnswer((_) => const Stream.empty());
    when(() => categories.getCategories(kind: any(named: 'kind')))
        .thenAnswer((_) async => const []);
    when(() => accounts.getAccounts()).thenAnswer(
      (_) async => const [
        AccountModel(
          currency: Currency.rub,
          id: 'card',
          name: 'Карта',
          type: AccountType.debit,
          balance: 0,
          color: EntityColor.yellow,
          isArchived: false,
        ),
      ],
    );
    getIt
      ..registerFactory(() => CategoryPickerCubit(categories))
      ..registerFactory(() => AccountsCubit(accounts, bus));
  });

  tearDown(() {
    getIt
      ..unregister<CategoryPickerCubit>()
      ..unregister<AccountsCubit>();
  });

  Future<void> pump(WidgetTester tester, RecurringFormState state) async {
    when(() => cubit.state).thenReturn(state);
    await pumpPage(
      tester,
      BlocProvider<RecurringFormCubit>.value(
        value: cubit,
        child: const RecurringEditView(),
      ),
      width: 600,
    );
    await settle(tester);
  }

  testWidgets('правка: сегменты типа неактивны', (tester) async {
    await pump(
      tester,
      RecurringFormState(recurringId: 'r1', anchor: DateTime(2026, 11, 3, 12)),
    );

    final segments = tester.widget<SegmentedButton<TransactionType>>(
      find.byType(SegmentedButton<TransactionType>),
    );
    expect(segments.onSelectionChanged, isNull);
  });

  testWidgets('суффикс суммы — валюта выбранного счёта', (tester) async {
    await pump(
      tester,
      RecurringFormState(
        accountId: 'card',
        accountCurrency: Currency.usd,
        anchor: DateTime(2026, 11, 3, 12),
      ),
    );

    expect(find.text(r'$'), findsOneWidget);
    expect(find.text('₽'), findsNothing);
  });

  testWidgets('счёт не выбран — суффикс из базовой валюты', (tester) async {
    await pump(tester, RecurringFormState(anchor: DateTime(2026, 11, 3, 12)));

    expect(find.text('₽'), findsOneWidget);
  });
}
