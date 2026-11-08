import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/features/settings/presentation/pages/about_page.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  for (final locale in const [Locale('ru'), Locale('en')]) {
    testWidgets('shows rates attribution and site (${locale.languageCode})', (
      tester,
    ) async {
      await pumpPage(tester, const AboutPage(), locale: locale);
      await settle(tester);

      // Текст обязателен у провайдера и одинаков в обеих локалях.
      expect(find.text('Rates By Exchange Rate API'), findsOneWidget);
      expect(find.text('exchangerate-api.com'), findsOneWidget);
    });
  }
}
