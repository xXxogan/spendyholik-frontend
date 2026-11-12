import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/storage/preferences_storage.dart';
import 'package:spendyholik/features/settings/data/models/models.dart';
import 'package:spendyholik/features/settings/data/repositories/settings_repository.dart';

@LazySingleton(as: SettingsRepository)
class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._storage);

  final PreferencesStorage _storage;

  static const _themeMode = 'settings.themeMode';
  static const _language = 'settings.language';
  static const _pushEnabled = 'settings.pushEnabled';

  @override
  Future<AppSettings> load() => _guard(() async {
    const defaults = AppSettings();
    final themeMode = await _storage.getString(_themeMode);
    final language = await _storage.getString(_language);
    return AppSettings(
      // Неизвестное значение (старая версия, ручная правка) — как без значения.
      themeMode:
          AppThemeMode.values.asNameMap()[themeMode] ?? defaults.themeMode,
      language: AppLanguage.values.asNameMap()[language] ?? defaults.language,
      pushEnabled: await _storage.getBool(_pushEnabled) ?? defaults.pushEnabled,
    );
  });

  @override
  Future<void> save(AppSettings settings) => _guard(() async {
    await _storage.setString(_themeMode, settings.themeMode.name);
    await _storage.setString(_language, settings.language.name);
    await _storage.setBool(_pushEnabled, settings.pushEnabled);
  });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Exception catch (error) {
      throw UnknownFailure(error);
    }
  }
}
