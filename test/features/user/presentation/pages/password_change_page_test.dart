import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/features/user/presentation/cubit/password_change_cubit.dart';
import 'package:spendyholik/features/user/presentation/pages/password_change_page.dart';

import '../../../../helpers/pump_app.dart';

class MockPasswordChangeCubit extends MockCubit<PasswordChangeState>
    implements PasswordChangeCubit {}

void main() {
  late MockPasswordChangeCubit cubit;

  setUp(() {
    cubit = MockPasswordChangeCubit();
    when(() => cubit.sendCode()).thenAnswer((_) async {});
    when(() => cubit.submit()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, PasswordChangeState state) async {
    when(() => cubit.state).thenReturn(state);
    await pumpPage(
      tester,
      BlocProvider<PasswordChangeCubit>.value(
        value: cubit,
        child: const PasswordChangeView(email: 'maria@example.com'),
      ),
      width: 600,
    );
    await settle(tester);
  }

  testWidgets('до кода — адрес и «Отправить код»; полей кода нет', (
    tester,
  ) async {
    await pump(tester, const PasswordChangeState());

    expect(find.textContaining('maria@example.com'), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
    await tester.tap(find.text('Отправить код'));
    verify(() => cubit.sendCode()).called(1);
  });

  testWidgets(
    'код отправлен — поле кода, новый пароль, отсчёт; «Сменить пароль»',
    (tester) async {
      await pump(
        tester,
        const PasswordChangeState(codeSent: true, resendIn: 30),
      );

      expect(find.text('Отправить снова через 30 с'), findsOneWidget);
      await tester.ensureVisible(find.text('Сменить пароль'));
      await tester.tap(find.text('Сменить пароль'));
      verify(() => cubit.submit()).called(1);
    },
  );

  testWidgets('ошибки у полей кода и пароля', (tester) async {
    await pump(
      tester,
      const PasswordChangeState(
        codeSent: true,
        fieldErrors: {
          PasswordChangeField.code: FieldError.invalidCode,
          PasswordChangeField.newPassword: FieldError.tooShort,
        },
      ),
    );

    expect(find.text('Неверный код'), findsOneWidget);
    expect(find.text('Слишком коротко'), findsOneWidget);
  });
}
