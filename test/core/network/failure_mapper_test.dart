import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/network/failure_mapper.dart';

DioException _response(int status, Object? data) {
  final options = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

Map<String, Object> _error(
  String code, [
  Map<String, String> errors = const {},
]) => {'code': code, 'detail': 'd', 'errors': errors};

void main() {
  test('нет ответа (Web: connectionError, таймаут) — NetworkFailure', () {
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    ]) {
      expect(
        mapDioException(
          DioException(requestOptions: RequestOptions(), type: type),
        ),
        isA<NetworkFailure>(),
        reason: '$type',
      );
    }
  });

  test('404 с HTML-телом — NotFoundFailure', () {
    expect(
      mapDioException(_response(404, '<html>Not Found</html>')),
      isA<NotFoundFailure>(),
    );
  });

  test('401 invalid_credentials — InvalidCredentialsFailure, прочий 401 — Unauthorized', () {
    expect(
      mapDioException(_response(401, _error('invalid_credentials'))),
      isA<InvalidCredentialsFailure>(),
    );
    expect(
      mapDioException(_response(401, _error('not_authenticated'))),
      isA<UnauthorizedFailure>(),
    );
  });

  test('email_already_taken — EmailTakenFailure', () {
    expect(
      mapDioException(_response(409, _error('email_already_taken'))),
      isA<EmailTakenFailure>(),
    );
  });

  test('422 с ошибкой поля — ValidationFailure с именем поля черновика', () {
    final failure = mapDioException(
      _response(422, _error('validation_error', {'amount_minor': 'too_small'})),
      fields: const {'amount_minor': 'amount'},
    );

    expect(failure, isA<ValidationFailure>());
    failure as ValidationFailure;
    expect(failure.field, 'amount');
    expect(failure.reason, FieldError.invalidAmount);
  });

  test('доменные коды полей переводятся в FieldError', () {
    const cases = {
      'required': FieldError.required,
      'too_short': FieldError.tooShort,
      'wrong_password': FieldError.wrongPassword,
      'insufficient_funds': FieldError.exceedsBalance,
      'currency_mismatch': FieldError.currencyMismatch,
      'something_new': FieldError.invalid,
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      final failure = mapDioException(
        _response(422, _error('validation_error', {'note': key})),
      );
      expect((failure as ValidationFailure).reason, value, reason: key);
    }
  });

  test('invalid у email — invalidEmail', () {
    final failure = mapDioException(
      _response(422, _error('validation_error', {'email': 'invalid'})),
    );
    expect((failure as ValidationFailure).reason, FieldError.invalidEmail);
  });

  test('5xx и 422 без полей — UnknownFailure', () {
    expect(mapDioException(_response(500, 'oops')), isA<UnknownFailure>());
    expect(
      mapDioException(_response(422, _error('validation_error'))),
      isA<UnknownFailure>(),
    );
  });
}
