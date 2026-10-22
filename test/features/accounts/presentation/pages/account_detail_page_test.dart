import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/models/entity_color.dart';
import 'package:spendyholik/features/accounts/data/models/account_model.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/account_detail_cubit.dart';
import 'package:spendyholik/features/accounts/presentation/pages/account_detail_page.dart';

import '../../../../helpers/pump_app.dart';

class MockAccountDetailCubit extends MockCubit<AccountDetailState>
    implements AccountDetailCubit {}

void main() {
  late MockAccountDetailCubit cubit;

  const account = AccountModel(
    id: 'card',
    name: 'Карта Тинькофф',
    type: AccountType.debit,
    balance: 8425000,
    color: EntityColor.blue,
    isArchived: false,
    cardLast4: '4831',
  );
  final history = [
    BalancePoint(at: DateTime(2026, 9, 14), balance: 7000000),
    BalancePoint(at: DateTime(2026, 10, 19), balance: 8425000),
  ];

  setUp(() => cubit = MockAccountDetailCubit());

  Future<void> pump(WidgetTester tester, AccountDetailState state) async {
    when(() => cubit.state).thenReturn(state);
    await pumpPage(
      tester,
      BlocProvider<AccountDetailCubit>.value(
        value: cubit,
        child: const AccountDetailView(),
      ),
    );
    await settle(tester);
  }

  testWidgets('loaded — баланс и подпись типа', (tester) async {
    await pump(tester, AccountDetailState.loaded(account, history));

    expect(find.text('84 250 ₽'), findsOneWidget);
    expect(find.textContaining('4831'), findsOneWidget);
  });

  testWidgets('«Архивировать» с подтверждением вызывает archive', (
    tester,
  ) async {
    when(() => cubit.archive()).thenAnswer((_) async {});
    await pump(tester, AccountDetailState.loaded(account, history));

    await tester.ensureVisible(find.text('Архивировать счёт'));
    await tester.tap(find.text('Архивировать счёт'));
    await settle(tester);
    await tester.tap(find.text('Архивировать'));
    await settle(tester);

    verify(() => cubit.archive()).called(1);
  });

  testWidgets('отмена в диалоге — архивации нет', (tester) async {
    await pump(tester, AccountDetailState.loaded(account, history));

    await tester.ensureVisible(find.text('Архивировать счёт'));
    await tester.tap(find.text('Архивировать счёт'));
    await settle(tester);
    await tester.tap(find.text('Отмена'));
    await settle(tester);

    verifyNever(() => cubit.archive());
  });

  testWidgets(
    'архивный счёт — вместо архивации «Вернуть из архива», он вызывает unarchive',
    (tester) async {
      when(() => cubit.unarchive()).thenAnswer((_) async {});
      await pump(
        tester,
        AccountDetailState.loaded(account.copyWith(isArchived: true), history),
      );

      expect(find.text('Архивировать счёт'), findsNothing);
      await tester.ensureVisible(find.text('Вернуть из архива'));
      await tester.tap(find.text('Вернуть из архива'));

      verify(() => cubit.unarchive()).called(1);
    },
  );

  testWidgets('активный счёт — кнопки возврата из архива нет', (tester) async {
    await pump(tester, AccountDetailState.loaded(account, history));

    expect(find.text('Вернуть из архива'), findsNothing);
  });
}
