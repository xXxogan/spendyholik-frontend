import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/user/data/models/user_model.dart';
import 'package:spendyholik/features/user/data/repositories/auth_repository.dart';
import 'package:spendyholik/features/user/presentation/cubit/email_confirm_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const verified = UserModel(id: 'u2', name: 'Иван', email: 'ivan@example.com');

void main() {
  late MockAuthRepository auth;

  setUp(() {
    auth = MockAuthRepository();
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  EmailConfirmCubit build() =>
      EmailConfirmCubit(auth)..init('ivan@example.com');

  test('верный код — success', () async {
    when(() => auth.confirmEmail('482913')).thenAnswer((_) async => verified);
    final cubit = build();

    await cubit.submit('482913');

    expect(cubit.state.status, FormStatus.success);
    await cubit.close();
  });

  test('неверный код — ошибка у поля, поле очищено', () async {
    when(() => auth.confirmEmail(any()))
        .thenThrow(const ValidationFailure('code', FieldError.invalidCode));
    final cubit = build();

    await cubit.submit('000000');

    expect(cubit.state.codeError, FieldError.invalidCode);
    expect(cubit.state.code, '');
    expect(cubit.state.status, FormStatus.failure);
    await cubit.close();
  });

  test('повторный onCompleted во время отправки — один запрос', () async {
    when(() => auth.confirmEmail(any())).thenAnswer((_) async => verified);
    final cubit = build();

    await Future.wait([cubit.submit('482913'), cubit.submit('482913')]);

    verify(() => auth.confirmEmail('482913')).called(1);
    await cubit.close();
  });

  test('ввод снимает ошибку кода', () async {
    when(() => auth.confirmEmail(any()))
        .thenThrow(const ValidationFailure('code', FieldError.invalidCode));
    final cubit = build();
    await cubit.submit('000000');

    cubit.codeChanged('4');

    expect(cubit.state.codeError, isNull);
    expect(cubit.state.code, '4');
    await cubit.close();
  });

  test('после открытия — 60 с до повторной отправки, отсчёт по секундам', () {
    fakeAsync((async) {
      final cubit = build();
      expect(cubit.state.resendIn, 60);

      async.elapse(const Duration(seconds: 1));
      expect(cubit.state.resendIn, 59);

      async.elapse(const Duration(seconds: 59));
      expect(cubit.state.resendIn, 0);
      cubit.close();
    });
  });

  test(
    'resend: до конца отсчёта — без запроса; после — запрос и новый отсчёт',
    () {
      fakeAsync((async) {
        when(() => auth.resendEmailCode()).thenAnswer((_) async => false);
        final cubit = build();

        cubit.resend();
        async.flushMicrotasks();
        verifyNever(() => auth.resendEmailCode());

        async.elapse(const Duration(seconds: 60));
        cubit.resend();
        async.flushMicrotasks();

        verify(() => auth.resendEmailCode()).called(1);
        expect(cubit.state.resendIn, 60);
        cubit.close();
      });
    },
  );

  test('resend: дневной лимит — ошибка, отсчёт не запускается', () {
    fakeAsync((async) {
      when(() => auth.resendEmailCode())
          .thenThrow(const RateLimitedFailure(daily: true));
      final cubit = build();
      async.elapse(const Duration(seconds: 60));

      cubit.resend();
      async.flushMicrotasks();

      expect(cubit.state.failure, isA<RateLimitedFailure>());
      expect(cubit.state.resendIn, 0);
      cubit.close();
    });
  });

  test('resend: подтверждённый профиль завершает сценарий', () {
    fakeAsync((async) {
      when(() => auth.resendEmailCode()).thenAnswer((_) async => true);
      final cubit = build();
      async.elapse(const Duration(seconds: 60));

      cubit.resend();
      async.flushMicrotasks();

      expect(cubit.state.status, FormStatus.success);
      expect(cubit.state.resendIn, 0);
      cubit.close();
    });
  });

  test('signOut — выход из сессии', () async {
    final cubit = build();
    await cubit.signOut();
    verify(() => auth.signOut()).called(1);
    await cubit.close();
  });
}
