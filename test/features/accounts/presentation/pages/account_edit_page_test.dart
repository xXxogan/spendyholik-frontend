import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/features/accounts/data/models/account_model.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/account_form_cubit.dart';
import 'package:spendyholik/features/accounts/presentation/pages/account_edit_page.dart';

import '../../../../helpers/pump_app.dart';

class MockAccountFormCubit extends MockCubit<AccountFormState>
    implements AccountFormCubit {}

void main() {
  late MockAccountFormCubit cubit;

  setUp(() => cubit = MockAccountFormCubit());

  Future<void> pump(WidgetTester tester, AccountFormState state) async {
    when(() => cubit.state).thenReturn(state);
    await pumpPage(
      tester,
      BlocProvider<AccountFormCubit>.value(
        value: cubit,
        child: const AccountEditView(),
      ),
    );
    await settle(tester);
  }

  testWidgets('новый счёт — заголовок и начальный баланс', (tester) async {
    await pump(tester, const AccountFormState());

    expect(find.text('Новый счёт'), findsWidgets);
    expect(find.text('Начальный баланс'), findsOneWidget);
  });

  testWidgets('правка — текущий баланс вместо начального', (tester) async {
    await pump(
      tester,
      const AccountFormState(accountId: 'card', name: 'Карта'),
    );

    expect(find.text('Изменить счёт'), findsWidgets);
    expect(find.text('Текущий баланс'), findsOneWidget);
    expect(find.text('Начальный баланс'), findsNothing);
  });

  testWidgets('«Сохранить» вызывает save', (tester) async {
    when(() => cubit.save()).thenAnswer((_) async {});
    await pump(tester, const AccountFormState());

    await tester.ensureVisible(find.text('Сохранить'));
    await tester.tap(find.text('Сохранить'));

    verify(() => cubit.save()).called(1);
  });

  testWidgets('ошибка required — текст у поля', (tester) async {
    await pump(
      tester,
      const AccountFormState(
        fieldErrors: {AccountField.name: FieldError.required},
      ),
    );

    expect(find.text('Обязательное поле'), findsOneWidget);
  });

  testWidgets('поля по типу: вклад — ставка, без карты и лимита', (
    tester,
  ) async {
    await pump(tester, const AccountFormState(type: AccountType.savings));

    expect(find.text('Ставка, % годовых'), findsOneWidget);
    expect(find.text('Последние 4 цифры карты'), findsNothing);
    expect(find.text('Кредитный лимит'), findsNothing);
  });

  testWidgets('поля по типу: кредитная — карта и лимит', (tester) async {
    await pump(tester, const AccountFormState(type: AccountType.credit));

    expect(find.text('Последние 4 цифры карты'), findsOneWidget);
    expect(find.text('Кредитный лимит'), findsOneWidget);
  });

  testWidgets('выбор типа вызывает typeChanged', (tester) async {
    await pump(tester, const AccountFormState());

    await tester.tap(find.text('Наличные'));

    verify(() => cubit.typeChanged(AccountType.cash)).called(1);
  });

  testWidgets('счёт не загрузился — ошибка и «Повторить» вместо формы', (
    tester,
  ) async {
    when(() => cubit.init('card')).thenAnswer((_) async {});
    await pump(
      tester,
      const AccountFormState(accountId: 'card', failure: NotFoundFailure()),
    );

    expect(find.text('Сохранить'), findsNothing);
    await tester.tap(find.text('Повторить'));

    verify(() => cubit.init('card')).called(1);
  });
}
