import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/user/data/models/user_model.dart';
import 'package:spendyholik/features/user/data/repositories/auth_repository.dart';
import 'package:spendyholik/features/user/presentation/cubit/profile_edit_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const maria = UserModel(
  id: 'u1',
  name: 'Мария Соколова',
  email: 'maria@example.com',
  baseCurrency: Currency.rub,
);

void main() {
  late MockAuthRepository auth;

  setUpAll(() => registerFallbackValue(Currency.rub));

  setUp(() {
    auth = MockAuthRepository();
    when(
      () => auth.updateProfile(
        name: any(named: 'name'),
        email: any(named: 'email'),
      ),
    ).thenAnswer((_) async => maria);
    when(() => auth.setBaseCurrency(any())).thenAnswer((_) async => maria);
    when(() => auth.changePassword(any(), any())).thenAnswer((_) async {});
  });

  ProfileEditCubit build() => ProfileEditCubit(auth)..init(maria);

  test('init — поля из пользователя', () {
    final state = build().state;
    expect(state.name, 'Мария Соколова');
    expect(state.email, 'maria@example.com');
    expect(state.currency, Currency.rub);
  });

  blocTest<ProfileEditCubit, ProfileEditState>(
    'пустое имя — required, без запроса',
    build: build,
    act: (cubit) => cubit
      ..nameChanged('  ')
      ..save(),
    skip: 1,
    expect: () => [
      isA<ProfileEditState>().having((s) => s.fieldErrors, 'errors', {
        ProfileField.name: FieldError.required,
      }),
    ],
    verify: (_) => verifyNever(
      () => auth.updateProfile(
        name: any(named: 'name'),
        email: any(named: 'email'),
      ),
    ),
  );

  blocTest<ProfileEditCubit, ProfileEditState>(
    'save: профиль и новая валюта, без смены пароля — success',
    build: build,
    act: (cubit) => cubit
      ..nameChanged('Мария Петрова')
      ..currencyChanged(Currency.usd)
      ..save(),
    skip: 3,
    expect: () => [
      isA<ProfileEditState>().having(
        (s) => s.status,
        'status',
        FormStatus.success,
      ),
    ],
    verify: (_) {
      verify(
        () => auth.updateProfile(
          name: 'Мария Петрова',
          email: 'maria@example.com',
        ),
      ).called(1);
      verify(() => auth.setBaseCurrency(Currency.usd)).called(1);
      verifyNever(() => auth.changePassword(any(), any()));
    },
  );

  blocTest<ProfileEditCubit, ProfileEditState>(
    'валюта не менялась — setBaseCurrency не зовём',
    build: build,
    act: (cubit) => cubit.save(),
    verify: (_) => verifyNever(() => auth.setBaseCurrency(any())),
  );

  blocTest<ProfileEditCubit, ProfileEditState>(
    'новый пароль короче 8 — tooShort, без текущего — required',
    build: build,
    act: (cubit) => cubit
      ..newPasswordChanged('1234')
      ..save(),
    skip: 1,
    expect: () => [
      isA<ProfileEditState>().having((s) => s.fieldErrors, 'errors', {
        ProfileField.currentPassword: FieldError.required,
        ProfileField.newPassword: FieldError.tooShort,
      }),
    ],
  );

  blocTest<ProfileEditCubit, ProfileEditState>(
    'неверный текущий пароль — ошибка у поля, профиль не сохраняется',
    setUp: () => when(() => auth.changePassword(any(), any())).thenThrow(
      const ValidationFailure('currentPassword', FieldError.wrongPassword),
    ),
    build: build,
    act: (cubit) => cubit
      ..nameChanged('Мария Петрова')
      ..currentPasswordChanged('wrong-pass')
      ..newPasswordChanged('new-pass-123')
      ..save(),
    skip: 4,
    expect: () => [
      isA<ProfileEditState>()
          .having((s) => s.status, 'status', FormStatus.failure)
          .having((s) => s.fieldErrors, 'errors', {
            ProfileField.currentPassword: FieldError.wrongPassword,
          }),
    ],
    verify: (_) => verifyNever(
      () => auth.updateProfile(
        name: any(named: 'name'),
        email: any(named: 'email'),
      ),
    ),
  );

  blocTest<ProfileEditCubit, ProfileEditState>(
    'email занят — ошибка у email',
    setUp: () => when(
      () => auth.updateProfile(
        name: any(named: 'name'),
        email: any(named: 'email'),
      ),
    ).thenThrow(const EmailTakenFailure()),
    build: build,
    act: (cubit) => cubit.save(),
    skip: 1,
    expect: () => [
      isA<ProfileEditState>().having((s) => s.fieldErrors, 'errors', {
        ProfileField.email: FieldError.emailTaken,
      }),
    ],
  );
}
