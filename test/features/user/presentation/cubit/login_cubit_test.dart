import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/user/data/models/user_model.dart';
import 'package:spendyholik/features/user/data/repositories/auth_repository.dart';
import 'package:spendyholik/features/user/presentation/cubit/login_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const maria = UserModel(id: 'u1', name: 'Мария', email: 'maria@example.com');

void main() {
  late MockAuthRepository auth;

  setUp(() => auth = MockAuthRepository());

  LoginCubit build() => LoginCubit(auth);

  blocTest<LoginCubit, LoginState>(
    'некорректный email и пустой пароль — ошибки полей, без запроса',
    build: build,
    act: (cubit) => cubit
      ..emailChanged('maria@')
      ..submit(),
    skip: 1,
    expect: () => [
      const LoginState(
        email: 'maria@',
        fieldErrors: {
          LoginField.email: FieldError.invalidEmail,
          LoginField.password: FieldError.required,
        },
      ),
    ],
    verify: (_) => verifyNever(() => auth.signIn(any(), any())),
  );

  blocTest<LoginCubit, LoginState>(
    'неверная пара — failure, поля не сброшены',
    setUp: () =>
        when(() => auth.signIn(any(), any()))
            .thenThrow(const InvalidCredentialsFailure()),
    build: build,
    act: (cubit) => cubit
      ..emailChanged(' maria@example.com ')
      ..passwordChanged('wrong-pass')
      ..submit(),
    skip: 3,
    expect: () => [
      const LoginState(
        email: ' maria@example.com ',
        password: 'wrong-pass',
        status: FormStatus.failure,
        failure: InvalidCredentialsFailure(),
      ),
    ],
    verify: (_) =>
        verify(() => auth.signIn('maria@example.com', 'wrong-pass')).called(1),
  );

  blocTest<LoginCubit, LoginState>(
    'верная пара — success',
    setUp: () =>
        when(() => auth.signIn(any(), any())).thenAnswer((_) async => maria),
    build: build,
    act: (cubit) => cubit
      ..emailChanged('maria@example.com')
      ..passwordChanged('secret-pass')
      ..submit(),
    skip: 3,
    expect: () => [
      isA<LoginState>().having((s) => s.status, 'status', FormStatus.success),
    ],
  );
}
