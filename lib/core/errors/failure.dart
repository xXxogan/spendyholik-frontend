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
  invalid,
}
