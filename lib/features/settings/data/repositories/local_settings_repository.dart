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
  static const _pushEnabled = 'settings.pushEnabled';
  static const _budgetReminders = 'settings.budgetReminders';
  static const _weeklyReport = 'settings.weeklyReport';

  @override
  Future<AppSettings> load() => _guard(() async {
    const defaults = AppSettings();
    final themeMode = await _storage.getString(_themeMode);
    return AppSettings(
      // Неизвестное значение (старая версия, ручная правка) — как без значения.
      themeMode:
          AppThemeMode.values.asNameMap()[themeMode] ?? defaults.themeMode,
      pushEnabled: await _storage.getBool(_pushEnabled) ?? defaults.pushEnabled,
      budgetReminders:
          await _storage.getBool(_budgetReminders) ?? defaults.budgetReminders,
      weeklyReport:
          await _storage.getBool(_weeklyReport) ?? defaults.weeklyReport,
    );
  });

  @override
  Future<void> save(AppSettings settings) => _guard(() async {
    await _storage.setString(_themeMode, settings.themeMode.name);
    await _storage.setBool(_pushEnabled, settings.pushEnabled);
    await _storage.setBool(_budgetReminders, settings.budgetReminders);
    await _storage.setBool(_weeklyReport, settings.weeklyReport);
  });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Exception catch (error) {
      throw UnknownFailure(error);
    }
  }
}
