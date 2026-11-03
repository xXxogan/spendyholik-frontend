import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/user/data/models/user_model.dart';
import 'package:spendyholik/features/user/data/repositories/auth_repository.dart';
import 'package:spendyholik/features/user/data/repositories/onboarding_repository.dart';
import 'package:spendyholik/features/user/presentation/cubit/session_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

const maria = UserModel(
  id: 'u1',
  name: 'Мария Соколова',
  email: 'maria@example.com',
  baseCurrency: Currency.rub,
);

void main() {
  late MockAuthRepository auth;
  late MockOnboardingRepository onboarding;
  late StreamController<UserModel?> userChanges;

  setUp(() {
    auth = MockAuthRepository();
    onboarding = MockOnboardingRepository();
    userChanges = StreamController<UserModel?>.broadcast();
    when(() => auth.userChanges).thenAnswer((_) => userChanges.stream);
  });

  tearDown(() => userChanges.close());

  SessionCubit build() => SessionCubit(auth, onboarding);

  test('до restore — unknown', () {
    expect(build().state, const SessionState.unknown());
  });

  blocTest<SessionCubit, SessionState>(
    'restore: пользователь есть — authenticated',
    setUp: () =>
        when(() => auth.restoreSession()).thenAnswer((_) async => maria),
    build: build,
    act: (cubit) => cubit.restore(),
    expect: () => [const SessionState.authenticated(maria)],
  );

  blocTest<SessionCubit, SessionState>(
    'restore: пользователя нет — unauthenticated с флагом онбординга',
    setUp: () {
      when(() => auth.restoreSession()).thenAnswer((_) async => null);
      when(() => onboarding.isSeen()).thenAnswer((_) async => false);
    },
    build: build,
    act: (cubit) => cubit.restore(),
    expect: () => [const SessionState.unauthenticated(onboardingSeen: false)],
  );

  blocTest<SessionCubit, SessionState>(
    'restore упал — unauthenticated, а не вечный splash',
    setUp: () {
      when(() => auth.restoreSession()).thenThrow(Exception('offline'));
      when(() => onboarding.isSeen()).thenAnswer((_) async => true);
    },
    build: build,
    act: (cubit) => cubit.restore(),
    expect: () => [const SessionState.unauthenticated(onboardingSeen: true)],
  );

  blocTest<SessionCubit, SessionState>(
    'userChanges: вышел — unauthenticated (онбординг уже видел)',
    setUp: () =>
        when(() => auth.restoreSession()).thenAnswer((_) async => maria),
    build: build,
    act: (cubit) async {
      await cubit.restore();
      userChanges.add(null);
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [
      const SessionState.authenticated(maria),
      const SessionState.unauthenticated(onboardingSeen: true),
    ],
  );
}
