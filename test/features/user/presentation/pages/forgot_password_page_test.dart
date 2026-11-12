import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/features/user/presentation/cubit/forgot_password_cubit.dart';
import 'package:spendyholik/features/user/presentation/pages/forgot_password_page.dart';

import '../../../../helpers/pump_app.dart';

class MockForgotPasswordCubit extends MockCubit<ForgotPasswordState>
    implements ForgotPasswordCubit {}

void main() {
  late MockForgotPasswordCubit cubit;

  setUp(() {
    cubit = MockForgotPasswordCubit();
    when(() => cubit.requestCode()).thenAnswer((_) async {});
    when(() => cubit.resend()).thenAnswer((_) async {});
    when(() => cubit.submit()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, ForgotPasswordState state) async {
    when(() => cubit.state).thenReturn(state);
    await pumpPage(
      tester,
      BlocProvider<ForgotPasswordCubit>.value(
        value: cubit,
        child: const ForgotPasswordView(),
      ),
      width: 600,
    );
    await settle(tester);
  }

  testWidgets('шаг email — поле адреса и «Получить код»', (tester) async {
    await pump(tester, const ForgotPasswordState());

    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.text('Получить код'));
    verify(() => cubit.requestCode()).called(1);
  });

  testWidgets('шаг email — ошибка адреса у поля', (tester) async {
    await pump(
      tester,
      const ForgotPasswordState(
        fieldErrors: {ForgotPasswordField.email: FieldError.invalidEmail},
      ),
    );

    expect(find.text('Некорректный email'), findsOneWidget);
  });

  testWidgets('шаг code — подсказка, отсчёт, «Сменить пароль» зовёт submit', (
    tester,
  ) async {
    await pump(
      tester,
      const ForgotPasswordState(
        step: ForgotPasswordStep.code,
        email: 'maria@example.com',
        resendIn: 30,
      ),
    );

    expect(find.textContaining('Если адрес зарегистрирован'), findsOneWidget);
    expect(find.text('Отправить снова через 30 с'), findsOneWidget);
    await tester.ensureVisible(find.text('Сменить пароль'));
    await tester.tap(find.text('Сменить пароль'));
    verify(() => cubit.submit()).called(1);
  });

  testWidgets('шаг code — ошибки у кода и пароля', (tester) async {
    await pump(
      tester,
      const ForgotPasswordState(
        step: ForgotPasswordStep.code,
        fieldErrors: {
          ForgotPasswordField.code: FieldError.invalidCode,
          ForgotPasswordField.newPassword: FieldError.tooShort,
        },
      ),
    );

    expect(find.text('Неверный код'), findsOneWidget);
    expect(find.text('Слишком коротко'), findsOneWidget);
  });
}
