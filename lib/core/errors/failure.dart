sealed class Failure implements Exception {
  const Failure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

final class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure();
}

final class EmailTakenFailure extends Failure {
  const EmailTakenFailure();
}

/// Почта не подтверждена: сервер закрыл данные до ввода кода из письма.
final class EmailNotVerifiedFailure extends Failure {
  const EmailNotVerifiedFailure();
}

final class EmailAlreadyVerifiedFailure extends Failure {
  const EmailAlreadyVerifiedFailure();
}

/// 429 без поля: код запрошен слишком рано или исчерпан дневной лимит.
final class RateLimitedFailure extends Failure {
  const RateLimitedFailure({required this.daily});

  /// true — лимит кодов на сутки, ждать до завтра; false — подождать минуту.
  final bool daily;
}

final class ValidationFailure extends Failure {
  const ValidationFailure(this.field, this.reason);

  final String field;
  final FieldError reason;
}

final class UnknownFailure extends Failure {
  const UnknownFailure([this.cause]);

  final Object? cause;
}

enum FieldError {
  required,
  invalidAmount,
  invalidEmail,
  tooShort,
  exceedsBalance,
  exceedsRemaining,
  exceedsTarget,
  sameAccount,
  wrongPassword,
  alreadyExists,
  belowRepaid,
  emailTaken,
  currencyMismatch,
  invalidCode,
  codeExpired,
  tooManyAttempts,
  invalid,
}
