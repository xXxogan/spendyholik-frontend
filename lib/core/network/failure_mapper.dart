import 'package:dio/dio.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/network/api_error_dto.dart';

const _amountCodes = {'too_small', 'too_large'};

const _fieldCodes = {
  'required': FieldError.required,
  'too_short': FieldError.tooShort,
  'wrong_password': FieldError.wrongPassword,
  'budget_already_exists': FieldError.alreadyExists,
  'insufficient_funds': FieldError.exceedsBalance,
  'exceeds_target': FieldError.exceedsTarget,
  'excessive_repayment': FieldError.exceedsRemaining,
  'below_repaid': FieldError.belowRepaid,
  'email_already_taken': FieldError.emailTaken,
  'currency_mismatch': FieldError.currencyMismatch,
  'invalid_code': FieldError.invalidCode,
  'code_expired': FieldError.codeExpired,
  'too_many_attempts': FieldError.tooManyAttempts,
};

/// [fields] — JSON-имя поля → имя поля черновика (`amount_minor` → `amount`).
Failure mapDioException(
  DioException e, {
  Map<String, String> fields = const {},
}) {
  switch (e.type) {
    case DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout:
      // На Web браузер не раскрывает причину сбоя (S-03): DNS, CORS и офлайн неразличимы.
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      return _fromResponse(e, fields);
    case DioExceptionType.cancel ||
        DioExceptionType.badCertificate ||
        DioExceptionType.transformTimeout ||
        DioExceptionType.unknown:
      return UnknownFailure(e);
  }
}

Failure _fromResponse(DioException e, Map<String, String> fields) {
  final status = e.response?.statusCode;
  if (status == 404) return const NotFoundFailure();
  final data = e.response?.data;
  // 404 и ошибки прокси приходят HTML-страницей, а не JSON.
  final error = data is Map<String, dynamic> ? _parse(data) : null;
  if (error == null) return UnknownFailure(e);

  switch (error.code) {
    case 'invalid_credentials':
      return const InvalidCredentialsFailure();
    case 'email_already_taken':
      return const EmailTakenFailure();
    case 'email_not_verified':
      return const EmailNotVerifiedFailure();
  }
  if (status == 401) return const UnauthorizedFailure();

  final entry = error.errors.entries.firstOrNull;
  // 429 с полем (too_many_attempts у code) — ошибка формы; без поля — лимит частоты.
  if (status == 429 && entry == null) {
    return RateLimitedFailure(daily: error.code == 'too_many_codes');
  }
  if (entry == null) return UnknownFailure(e);
  return ValidationFailure(
    fields[entry.key] ?? entry.key,
    _fieldError(entry.key, entry.value),
  );
}

ApiErrorDto? _parse(Map<String, dynamic> data) {
  try {
    return ApiErrorDto.fromJson(data);
  } on Object {
    return null;
  }
}

FieldError _fieldError(String field, String code) {
  if (_amountCodes.contains(code)) return FieldError.invalidAmount;
  if (code == 'invalid' && field == 'email') return FieldError.invalidEmail;
  return _fieldCodes[code] ?? FieldError.invalid;
}
