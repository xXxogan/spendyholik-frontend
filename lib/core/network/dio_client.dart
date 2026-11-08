import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/config/app_config.dart';
import 'package:spendyholik/core/network/api_interceptors.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  Dio dio(AuthInterceptor auth, Talker talker) =>
      _base()..interceptors.addAll([auth, _logger(talker)]);

  /// Только для refresh и повтора запроса после него — без AuthInterceptor.
  @Named(AuthInterceptor.refreshDioName)
  @lazySingleton
  Dio refreshDio(Talker talker) => _base()..interceptors.add(_logger(talker));

  static Dio _base() => Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
    ),
  );

  // Заголовки и тела не пишутся: в них токены, пароли и личные данные.
  static TalkerDioLogger _logger(Talker talker) => TalkerDioLogger(
    talker: talker,
    settings: const TalkerDioLoggerSettings(
      printRequestHeaders: false,
      printRequestData: false,
      printResponseData: false,
      printErrorHeaders: false,
    ),
  );
}
