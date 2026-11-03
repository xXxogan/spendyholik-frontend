import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/storage/preferences_storage.dart';
import 'package:spendyholik/features/user/data/repositories/onboarding_repository.dart';

@LazySingleton(as: OnboardingRepository)
class LocalOnboardingRepository implements OnboardingRepository {
  LocalOnboardingRepository(this._storage);

  final PreferencesStorage _storage;

  static const _seen = 'user.onboardingSeen';

  @override
  Future<bool> isSeen() async => await _storage.getBool(_seen) ?? false;

  @override
  Future<void> markSeen() => _storage.setBool(_seen, true);
}
