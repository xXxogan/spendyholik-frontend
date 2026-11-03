import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/core/storage/preferences_storage.dart';
import 'package:spendyholik/features/settings/data/models/app_settings.dart';
import 'package:spendyholik/features/settings/data/repositories/local_settings_repository.dart';

class _MemoryStorage implements PreferencesStorage {
  final values = <String, Object>{};

  @override
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

void main() {
  late _MemoryStorage storage;
  late LocalSettingsRepository repository;

  setUp(() {
    storage = _MemoryStorage();
    repository = LocalSettingsRepository(storage);
  });

  test('ключей нет — значения по умолчанию', () async {
    expect(await repository.load(), const AppSettings());
  });

  test('save → load возвращает то же', () async {
    const settings = AppSettings(
      themeMode: AppThemeMode.dark,
      pushEnabled: false,
      budgetReminders: false,
      weeklyReport: true,
    );

    await repository.save(settings);

    expect(await repository.load(), settings);
    expect(storage.values['settings.themeMode'], 'dark');
  });

  test('мусор в themeMode — system', () async {
    storage.values['settings.themeMode'] = 'purple';

    expect((await repository.load()).themeMode, AppThemeMode.system);
  });
}
