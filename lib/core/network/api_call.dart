import 'package:dio/dio.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/network/failure_mapper.dart';

/// Вызов API из репозитория: наверх уходит только [Failure].
///
/// Retrofit пробрасывает ошибку разбора ответа как есть (TypeError,
/// FormatException) — это не Exception, Cubit-ы её не ловят, и экран
/// оставался бы на скелетоне (аудит 2026-11-09).
Future<T> callApi<T>(
  Future<T> Function() request, {
  Map<String, String> fields = const {},
}) async {
  try {
    return await request();
  } on DioException catch (e) {
    throw mapDioException(e, fields: fields);
  } on Failure {
    rethrow;
  } on Object catch (error) {
    throw UnknownFailure(error);
  }
}
