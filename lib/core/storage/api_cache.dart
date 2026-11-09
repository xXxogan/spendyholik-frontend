/// Последние ответы API для показа без сети. Только чтение: записи без сети нет.
abstract interface class ApiCache {
  /// JSON ответа или null, если его нет или он не читается.
  Future<String?> read(String key);

  Future<void> write(String key, String json);

  /// Выход и удаление данных: чужие данные не должны показаться следующему.
  Future<void> clear();

  /// Растёт с каждым [clear]: ответ на запрос, начатый до очистки, в кэш
  /// не пишется — иначе после выхода вернулись бы данные прежнего пользователя.
  int get generation;
}
