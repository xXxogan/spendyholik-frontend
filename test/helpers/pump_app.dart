import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_theme.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Страница в окружении приложения: тема, локализации, предок Material.
Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  double width = 400,
  Locale locale = const Locale('ru'),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      builder: (_, child) => Material(type: .transparency, child: child),
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizationsSetup.delegates,
      supportedLocales: AppLocalizationsSetup.supportedLocales,
      home: page,
    ),
  );
}

// Скелетоны крутят бесконечный shimmer — pumpAndSettle не дождётся покоя.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
