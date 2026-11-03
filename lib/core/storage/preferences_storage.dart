import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Локальные настройки устройства; данные приложения сюда не кладутся.
@lazySingleton
class PreferencesStorage {
  PreferencesStorage(this._preferences);

  final SharedPreferencesAsync _preferences;

  Future<String?> getString(String key) => _preferences.getString(key);

  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);

  Future<bool?> getBool(String key) => _preferences.getBool(key);

  Future<void> setBool(String key, bool value) =>
      _preferences.setBool(key, value);

  Future<void> remove(String key) => _preferences.remove(key);
}
