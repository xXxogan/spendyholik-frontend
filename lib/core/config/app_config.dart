abstract final class AppConfig {
  static const appVersion = '1.0.0';
  static const fakeLatency = Duration(milliseconds: 400);

  static const apiBaseUrl = 'https://api.spendyholik.duckdns.org/api/v1/';

  // Медиана ответа 85–330 мс, холодный старт до 0,7 с (спайк S-03).
  // sendTimeout не задаётся: на Web без тела запроса Dio на нём падает.
  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 20);

  /// limit API операций: 1–100.
  static const transactionsPageSize = 50;
}
