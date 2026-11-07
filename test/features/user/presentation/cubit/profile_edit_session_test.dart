import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/fake_backend/seed.dart';
import 'package:spendyholik/features/user/data/repositories/fake_auth_repository.dart';
import 'package:spendyholik/features/user/data/repositories/onboarding_repository.dart';
import 'package:spendyholik/features/user/presentation/cubit/profile_edit_cubit.dart';
import 'package:spendyholik/features/user/presentation/cubit/session_cubit.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  test('save — сессия получает новое имя и валюту', () async {
    final auth = FakeAuthRepository(FakeBackend());
    final session = SessionCubit(auth, MockOnboardingRepository());
    addTearDown(session.close);
    final user = await auth.signIn(FakeSeed.email, FakeSeed.password);
    await session.waitFor((s) => s is SessionAuthenticated);

    final cubit = ProfileEditCubit(auth)
      ..init(user)
      ..nameChanged('Мария Иванова')
      ..currencyChanged(Currency.usd);
    await cubit.save();

    final state = await session.waitFor(
      (s) => s is SessionAuthenticated && s.user.baseCurrency == Currency.usd,
      timeout: const Duration(seconds: 1),
    );
    expect(state, isA<SessionAuthenticated>());
    final updated = (state! as SessionAuthenticated).user;
    expect(updated.name, 'Мария Иванова');
    expect(updated.baseCurrency, Currency.usd);
  });
}
