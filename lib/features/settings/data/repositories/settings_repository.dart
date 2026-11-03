import 'package:spendyholik/features/settings/data/models/models.dart';

/// Настройки устройства: в фазе 2 остаются локальными, бэкенд их не хранит.
abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
