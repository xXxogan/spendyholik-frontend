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
        currentPassword: any(named: 'currentPassword'),
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
        currentPassword: any(named: 'currentPassword'),
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
    'сохранение профиля пароль не трогает — он меняется на своём экране по коду',
    build: build,
    act: (cubit) => cubit.save(),
    verify: (_) => verifyNever(() => auth.changePassword(any(), any())),
  );

  blocTest<ProfileEditCubit, ProfileEditState>(
    'email занят — ошибка у email',
    setUp: () => when(
      () => auth.updateProfile(
        name: any(named: 'name'),
        email: any(named: 'email'),
        currentPassword: any(named: 'currentPassword'),
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

  group('смена email (круг 3)', () {
    blocTest<ProfileEditCubit, ProfileEditState>(
      'только имя — без текущего пароля',
      setUp: () => when(
        () => auth.updateProfile(
          name: any(named: 'name'),
          email: any(named: 'email'),
          currentPassword: any(named: 'currentPassword'),
        ),
      ).thenAnswer((_) async => maria),
      build: build,
      act: (cubit) => cubit
        ..nameChanged('Мария Иванова')
        ..save(),
      verify: (cubit) {
        expect(cubit.state.emailChanged, isFalse);
        verify(
          () => auth.updateProfile(
            name: 'Мария Иванова',
            email: maria.email,
            currentPassword: null,
          ),
        ).called(1);
      },
    );

    blocTest<ProfileEditCubit, ProfileEditState>(
      'email изменён без пароля — ошибка у поля, запрос не уходит',
      build: build,
      act: (cubit) => cubit
        ..emailChanged('new@example.com')
        ..save(),
      verify: (cubit) {
        expect(cubit.state.emailChanged, isTrue);
        expect(cubit.state.fieldErrors, {
          ProfileField.currentPassword: FieldError.required,
        });
        verifyNever(
          () => auth.updateProfile(
            name: any(named: 'name'),
            email: any(named: 'email'),
            currentPassword: any(named: 'currentPassword'),
          ),
        );
      },
    );

    blocTest<ProfileEditCubit, ProfileEditState>(
      'email с паролем — пароль уходит; неверный — ошибка у поля',
      setUp: () =>
          when(
            () => auth.updateProfile(
              name: any(named: 'name'),
              email: any(named: 'email'),
              currentPassword: any(named: 'currentPassword'),
            ),
          ).thenThrow(
            const ValidationFailure(
              'currentPassword',
              FieldError.wrongPassword,
            ),
          ),
      build: build,
      act: (cubit) => cubit
        ..emailChanged('new@example.com')
        ..currentPasswordChanged('nope')
        ..save(),
      verify: (cubit) {
        verify(
          () => auth.updateProfile(
            name: any(named: 'name'),
            email: 'new@example.com',
            currentPassword: 'nope',
          ),
        ).called(1);
        expect(cubit.state.fieldErrors, {
          ProfileField.currentPassword: FieldError.wrongPassword,
        });
      },
    );

    blocTest<ProfileEditCubit, ProfileEditState>(
      'вернул прежний email — пароль снова не нужен',
      build: build,
      act: (cubit) => cubit
        ..emailChanged('new@example.com')
        ..emailChanged(maria.email),
      verify: (cubit) => expect(cubit.state.emailChanged, isFalse),
    );
  });
}
