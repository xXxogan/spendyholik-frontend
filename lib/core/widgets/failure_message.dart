import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/l10n/l10n.dart';

String failureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.errorNetwork,
      NotFoundFailure() => l10n.errorNotFound,
      InvalidCredentialsFailure() => l10n.errorInvalidCredentials,
      _ => l10n.errorUnknown,
    };
