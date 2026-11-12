import 'package:spendyholik/features/settings/data/models/models.dart';

/// Бросает только [Failure] из `core/errors`.
abstract interface class NotificationPreferencesRepository {
  /// Без сети — последнее известное значение из кэша.
  Future<NotificationPreferences> load();

  /// Ответ сервера — то, что теперь сохранено.
  Future<NotificationPreferences> save(NotificationPreferences preferences);
}
