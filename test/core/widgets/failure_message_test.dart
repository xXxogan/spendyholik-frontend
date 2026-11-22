import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/widgets/failure_message.dart';
import 'package:spendyholik/core/widgets/field_error_text.dart';
import 'package:spendyholik/l10n/l10n.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ru'));
  });

  test(
    'ValidationFailure без своего поля в форме — не «Что-то пошло не так»',
    () {
      expect(
        failureMessage(
          l10n,
          const ValidationFailure('note', FieldError.invalid),
        ),
        'Проверьте введённые данные',
      );
    },
  );

  test('currencyMismatch подходит и переводу, и цели, и долгу', () {
    expect(
      fieldErrorText(l10n, FieldError.currencyMismatch),
      'Валюты не совпадают',
    );
  });
}
