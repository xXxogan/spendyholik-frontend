import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/l10n/l10n.dart';

void main() {
  const supported = AppLocalizationsSetup.supportedLocales;

  test('язык системы поддерживается — берём его, регион не важен', () {
    expect(
      AppLocalizationsSetup.resolve([const Locale('en', 'GB')], supported),
      const Locale('en'),
    );
  });

  test(
    'первый предпочитаемый не поддерживается — берём следующий подходящий',
    () {
      expect(
        AppLocalizationsSetup.resolve([
          const Locale('de'),
          const Locale('en'),
        ], supported),
        const Locale('en'),
      );
    },
  );

  test('ни один язык не поддерживается — русский', () {
    expect(
      AppLocalizationsSetup.resolve([const Locale('de')], supported),
      const Locale('ru'),
    );
    expect(AppLocalizationsSetup.resolve(null, supported), const Locale('ru'));
  });
}
