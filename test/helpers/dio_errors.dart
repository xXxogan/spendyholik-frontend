import 'package:dio/dio.dart';

DioException apiError(
  int status,
  String code, [
  Map<String, String> errors = const {},
]) {
  final options = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {'code': code, 'detail': 'd', 'errors': errors},
    ),
  );
}

DioException networkError() => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.connectionError,
);
