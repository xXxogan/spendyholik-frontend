import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/user/data/repositories/auth_repository.dart';
import 'package:spendyholik/features/user/presentation/cubit/forgot_password_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;

  setUp(() {
    auth = MockAuthRepository();
    when(() => auth.requestPasswordReset(any())).thenAnswer((_) async {});
    when(() => auth.confirmPasswordReset(any(), any(), any()))
        .thenAnswer((_) async {});
  });

  ForgotPasswordCubit build() => ForgotPasswordCubit(auth);

  test('кривой email — ошибка у поля, запроса нет, шаг email', () async {
    final cubit = build()..emailChanged('not-an-email');

    await cubit.requestCode();

    expect(cubit.state.fieldErrors, {
      ForgotPasswordField.email: FieldError.invalidEmail,
    });
    expect(cubit.state.step, ForgotPasswordStep.email);
    verifyNever(() => auth.requestPasswordReset(any()));
    await cubit.close();
  });

  test('верный email — запрос, шаг code и отсчёт 60 с', () {
    fakeAsync((async) {
      final cubit = build()..emailChanged(' maria@example.com ');

      cubit.requestCode();
      async.flushMicrotasks();

      verify(() => auth.requestPasswordReset('maria@example.com')).called(1);
      expect(cubit.state.step, ForgotPasswordStep.code);
      expect(cubit.state.resendIn, 60);
      async.elapse(const Duration(seconds: 60));
      expect(cubit.state.resendIn, 0);
      cubit.close();
    });
  });

  test('повторная отправка во время запроса — no-op', () async {
    final cubit = build()..emailChanged('maria@example.com');

    await Future.wait([cubit.requestCode(), cubit.requestCode()]);

    verify(() => auth.requestPasswordReset(any())).called(1);
    await cubit.close();
  });

  test('429 «подождите» — сообщение, шаг остаётся email', () async {
    when(() => auth.requestPasswordReset(any()))
        .thenThrow(const RateLimitedFailure(daily: true));
    final cubit = build()..emailChanged('maria@example.com');

    await cubit.requestCode();

    expect(cubit.state.failure, isA<RateLimitedFailure>());
    expect(cubit.state.step, ForgotPasswordStep.email);
    expect(cubit.state.resendIn, 0);
    await cubit.close();
  });

  test('resend до конца отсчёта — без запроса, после — новый запрос', () {
    fakeAsync((async) {
      final cubit = build()..emailChanged('maria@example.com');
      cubit.requestCode();
      async.flushMicrotasks();

      cubit.resend();
      async.flushMicrotasks();
      verify(() => auth.requestPasswordReset(any())).called(1);

      async.elapse(const Duration(seconds: 60));
      cubit.resend();
      async.flushMicrotasks();
      verify(() => auth.requestPasswordReset(any())).called(1);
      expect(cubit.state.resendIn, 60);
      cubit.close();
    });
  });

  test('resend: недневной 429 запускает отсчёт', () {
    fakeAsync((async) {
      final cubit = build()..emailChanged('maria@example.com');
      cubit.requestCode();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 60));
      when(() => auth.requestPasswordReset(any()))
          .thenThrow(const RateLimitedFailure(daily: false));

      cubit.resend();
      async.flushMicrotasks();

      expect(cubit.state.failure, isA<RateLimitedFailure>());
      expect(cubit.state.resendIn, 60);
      cubit.close();
    });
  });

  Future<ForgotPasswordCubit> atCodeStep() async {
    final cubit = build()..emailChanged('maria@example.com');
    await cubit.requestCode();
    return cubit;
  }

  test('без кода и с коротким паролем — ошибки у полей, запроса нет', () async {
    final cubit = await atCodeStep();
    cubit.newPasswordChanged('1234567');

    await cubit.submit();

    expect(cubit.state.fieldErrors, {
      ForgotPasswordField.code: FieldError.required,
      ForgotPasswordField.newPassword: FieldError.tooShort,
    });
    verifyNever(() => auth.confirmPasswordReset(any(), any(), any()));
    await cubit.close();
  });

  test('код и пароль — confirmPasswordReset, шаг done', () async {
    final cubit = await atCodeStep();
    cubit
      ..codeChanged('482913')
      ..newPasswordChanged('new-secret');

    await cubit.submit();

    verify(
      () => auth.confirmPasswordReset(
        'maria@example.com',
        '482913',
        'new-secret',
      ),
    ).called(1);
    expect(cubit.state.step, ForgotPasswordStep.done);
    await cubit.close();
  });

  test('неверный код — ошибка у code, код очищен, пароль цел', () async {
    when(() => auth.confirmPasswordReset(any(), any(), any()))
        .thenThrow(const ValidationFailure('code', FieldError.invalidCode));
    final cubit = await atCodeStep();
    cubit
      ..codeChanged('000000')
      ..newPasswordChanged('new-secret');

    await cubit.submit();

    expect(
      cubit.state.fieldErrors[ForgotPasswordField.code],
      FieldError.invalidCode,
    );
    expect(cubit.state.code, '');
    expect(cubit.state.newPassword, 'new-secret');
    expect(cubit.state.step, ForgotPasswordStep.code);
    await cubit.close();
  });

  test('429 без поля при подтверждении — failure', () async {
    when(() => auth.confirmPasswordReset(any(), any(), any()))
        .thenThrow(const RateLimitedFailure(daily: false));
    final cubit = await atCodeStep();
    cubit
      ..codeChanged('000000')
      ..newPasswordChanged('new-secret');

    await cubit.submit();

    expect(cubit.state.failure, isA<RateLimitedFailure>());
    expect(cubit.state.step, ForgotPasswordStep.code);
    await cubit.close();
  });

  test('ввод снимает ошибку своего поля', () async {
    final cubit = await atCodeStep();
    await cubit.submit();

    cubit.codeChanged('1');

    expect(
      cubit.state.fieldErrors.containsKey(ForgotPasswordField.code),
      false,
    );
    await cubit.close();
  });

  test('FormStatus используется для submit', () async {
    final cubit = await atCodeStep();
    cubit
      ..codeChanged('482913')
      ..newPasswordChanged('new-secret');
    final future = cubit.submit();
    expect(cubit.state.status, FormStatus.submitting);
    await future;
    await cubit.close();
  });
}
