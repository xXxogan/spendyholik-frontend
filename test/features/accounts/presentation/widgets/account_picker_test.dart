import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/repositories.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:spendyholik/features/accounts/presentation/widgets/account_picker.dart';

import '../../../../helpers/pump_app.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

AccountModel account(String id, {bool archived = false}) => AccountModel(
  id: id,
  name: id,
  type: AccountType.debit,
  balance: 0,
  color: EntityColor.blue,
  isArchived: archived,
);

void main() {
  setUp(() {
    final repository = MockAccountRepository();
    final bus = MockDataChangeBus();
    when(() => bus.changes).thenAnswer((_) => const Stream.empty());
    when(() => repository.getAccounts()).thenAnswer(
      (_) async => [account('card'), account('old', archived: true)],
    );
    getIt.registerFactory(() => AccountsCubit(repository, bus));
  });

  tearDown(() => getIt.unregister<AccountsCubit>());

  Future<void> pump(WidgetTester tester, String? selected) async {
    await pumpPage(
      tester,
      AccountPicker(label: 'Счёт', selected: selected, onSelected: (_) {}),
    );
    await settle(tester);
  }

  testWidgets('архивные счета не предлагаются', (tester) async {
    await pump(tester, 'card');

    expect(find.text('card'), findsOneWidget);
    expect(find.text('old'), findsNothing);
  });

  testWidgets(
    'уже выбранный архивный счёт остаётся в поле (правка старой операции)',
    (tester) async {
      await pump(tester, 'old');

      expect(find.text('old'), findsOneWidget);
    },
  );
}
