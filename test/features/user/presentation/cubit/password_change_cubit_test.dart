import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/user/data/repositories/auth_repository.dart';
import 'package:spendyholik/features/user/presentation/cubit/password_change_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;

  setUp(() {
    auth = MockAuthRepository();
    when(() => auth.requestPasswordChangeCode()).thenAnswer((_) async {});
    when(() => auth.changePassword(any(), any())).thenAnswer((_) async {});
  });

  PasswordChangeCubit build() => PasswordChangeCubit(auth);

  test('«Отправить код» — запрос, поле кода и отсчёт 60 с', () {
    fakeAsync((async) {
      final cubit = build();

      cubit.sendCode();
      async.flushMicrotasks();

      verify(() => auth.requestPasswordChangeCode()).called(1);
      expect(cubit.state.codeSent, isTrue);
      expect(cubit.state.resendIn, 60);
      async.elapse(const Duration(seconds: 60));
      expect(cubit.state.resendIn, 0);
      cubit.close();
    });
  });

  test('повторная отправка до конца отсчёта — без запроса', () {
    fakeAsync((async) {
      final cubit = build();
      cubit.sendCode();
      async.flushMicrotasks();

      cubit.sendCode();
      async.flushMicrotasks();

      verify(() => auth.requestPasswordChangeCode()).called(1);
      cubit.close();
    });
  });

  test(
    'слишком часто — сообщение, отсчёт; дневной лимит — без отсчёта',
    () async {
      when(() => auth.requestPasswordChangeCode())
          .thenThrow(const RateLimitedFailure(daily: true));
      final cubit = build();

      await cubit.sendCode();

      expect(cubit.state.failure, isA<RateLimitedFailure>());
      expect(cubit.state.codeSent, isFalse);
      expect(cubit.state.resendIn, 0);
      await cubit.close();
    },
  );

  test(
    'без кода и с коротким паролем — ошибки у полей, запрос не уходит',
    () async {
      final cubit = build();
      await cubit.sendCode();
      cubit.newPasswordChanged('1234567');

      await cubit.submit();

      expect(cubit.state.fieldErrors, {
        PasswordChangeField.code: FieldError.required,
        PasswordChangeField.newPassword: FieldError.tooShort,
      });
      verifyNever(() => auth.changePassword(any(), any()));
      await cubit.close();
    },
  );

  test('код и пароль — changePassword, success', () async {
    final cubit = build();
    await cubit.sendCode();
    cubit
      ..codeChanged('482913')
      ..newPasswordChanged('new-secret');

    await cubit.submit();

    verify(() => auth.changePassword('482913', 'new-secret')).called(1);
    expect(cubit.state.status, FormStatus.success);
    await cubit.close();
  });

  test('неверный код — ошибка у поля кода, код очищен', () async {
    when(() => auth.changePassword(any(), any()))
        .thenThrow(const ValidationFailure('code', FieldError.invalidCode));
    final cubit = build();
    await cubit.sendCode();
    cubit
      ..codeChanged('000000')
      ..newPasswordChanged('new-secret');

    await cubit.submit();

    expect(
      cubit.state.fieldErrors[PasswordChangeField.code],
      FieldError.invalidCode,
    );
    expect(cubit.state.code, '');
    expect(cubit.state.newPassword, 'new-secret');
    await cubit.close();
  });

  test('ввод снимает ошибку своего поля', () async {
    final cubit = build();
    await cubit.sendCode();
    await cubit.submit();

    cubit.codeChanged('1');

    expect(
      cubit.state.fieldErrors.containsKey(PasswordChangeField.code),
      isFalse,
    );
    await cubit.close();
  });
}
