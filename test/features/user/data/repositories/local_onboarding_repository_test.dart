import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/storage/preferences_storage.dart';
import 'package:spendyholik/features/user/data/repositories/local_onboarding_repository.dart';

class _MemoryStorage implements PreferencesStorage {
  final values = <String, Object>{};

  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BrokenStorage implements PreferencesStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(Exception('storage unavailable'));
}

void main() {
  test('флага нет — не видел; markSeen → видел', () async {
    final repository = LocalOnboardingRepository(_MemoryStorage());

    expect(await repository.isSeen(), isFalse);
    await repository.markSeen();
    expect(await repository.isSeen(), isTrue);
  });

  test('хранилище бросает — UnknownFailure', () async {
    final repository = LocalOnboardingRepository(_BrokenStorage());

    await expectLater(repository.isSeen(), throwsA(isA<UnknownFailure>()));
    await expectLater(repository.markSeen(), throwsA(isA<UnknownFailure>()));
  });
}
