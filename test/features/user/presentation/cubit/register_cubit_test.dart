import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/user/data/models/user_model.dart';
import 'package:spendyholik/features/user/data/repositories/auth_repository.dart';
import 'package:spendyholik/features/user/presentation/cubit/register_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const ivan = UserModel(id: 'u2', name: 'Иван', email: 'ivan@example.com');

void main() {
  late MockAuthRepository auth;

  setUp(() => auth = MockAuthRepository());

  RegisterCubit build() => RegisterCubit(auth);

  RegisterCubit filled(RegisterCubit cubit, {String password = '12345678'}) =>
      cubit
        ..nameChanged('Иван')
        ..emailChanged('ivan@example.com')
        ..passwordChanged(password);

  blocTest<RegisterCubit, RegisterState>(
    'пусто — required у имени, invalidEmail, tooShort; без запроса',
    build: build,
    act: (cubit) => cubit.submit(),
    expect: () => [
      const RegisterState(
        fieldErrors: {
          RegisterField.name: FieldError.required,
          RegisterField.email: FieldError.invalidEmail,
          RegisterField.password: FieldError.tooShort,
        },
      ),
    ],
    verify: (_) => verifyNever(() => auth.register(any(), any(), any())),
  );

  blocTest<RegisterCubit, RegisterState>(
    'пароль из 7 символов — tooShort, из 8 — уже нет',
    setUp: () =>
        when(() => auth.register(any(), any(), any()))
            .thenAnswer((_) async => ivan),
    build: build,
    act: (cubit) async {
      await filled(cubit, password: '1234567').submit();
      cubit.passwordChanged('12345678');
      await cubit.submit();
    },
    skip: 3,
    expect: () => [
      isA<RegisterState>().having((s) => s.fieldErrors, 'errors', {
        RegisterField.password: FieldError.tooShort,
      }),
      isA<RegisterState>().having((s) => s.fieldErrors, 'errors', isEmpty),
      isA<RegisterState>().having(
        (s) => s.status,
        'status',
        FormStatus.submitting,
      ),
      isA<RegisterState>().having(
        (s) => s.status,
        'status',
        FormStatus.success,
      ),
    ],
    verify: (_) =>
        verify(() => auth.register('Иван', 'ivan@example.com', '12345678'))
            .called(1),
  );

  blocTest<RegisterCubit, RegisterState>(
    'email занят — ошибка у email, остальное на месте',
    setUp: () =>
        when(() => auth.register(any(), any(), any()))
            .thenThrow(const EmailTakenFailure()),
    build: build,
    act: (cubit) => filled(cubit).submit(),
    skip: 4,
    expect: () => [
      const RegisterState(
        name: 'Иван',
        email: 'ivan@example.com',
        password: '12345678',
        status: FormStatus.failure,
        fieldErrors: {RegisterField.email: FieldError.emailTaken},
      ),
    ],
  );
}
