import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/l10n/l10n.dart';

String fieldErrorText(AppLocalizations l10n, FieldError error) =>
    switch (error) {
      FieldError.required => l10n.fieldErrorRequired,
      FieldError.invalidAmount => l10n.fieldErrorInvalidAmount,
      FieldError.invalidEmail => l10n.fieldErrorInvalidEmail,
      FieldError.tooShort => l10n.fieldErrorTooShort,
      FieldError.exceedsBalance => l10n.fieldErrorExceedsBalance,
      FieldError.exceedsRemaining => l10n.fieldErrorExceedsRemaining,
      FieldError.exceedsTarget => l10n.fieldErrorExceedsTarget,
      FieldError.sameAccount => l10n.fieldErrorSameAccount,
      FieldError.wrongPassword => l10n.fieldErrorWrongPassword,
      FieldError.alreadyExists => l10n.fieldErrorAlreadyExists,
      FieldError.belowRepaid => l10n.fieldErrorBelowRepaid,
    };
