import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/l10n/l10n.dart';

String failureMessage(
  AppLocalizations l10n,
  Failure failure,
) => switch (failure) {
  NetworkFailure() => l10n.errorNetwork,
  NotFoundFailure() => l10n.errorNotFound,
  InvalidCredentialsFailure() => l10n.errorInvalidCredentials,
  EmailNotVerifiedFailure() => l10n.errorEmailNotVerified,
  RateLimitedFailure(daily: true) => l10n.errorRateLimitedDaily,
  RateLimitedFailure() => l10n.errorRateLimitedSoon,
  // Сюда доходят только поля, которых нет в форме: их ошибку показать негде.
  ValidationFailure() => l10n.errorValidation,
  _ => l10n.errorUnknown,
};
