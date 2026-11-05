import 'package:flutter_localizations/flutter_localizations.dart' as framework;
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/l10n/app_localizations.dart';

abstract final class AppLocalizationsSetup {
  // Сгенерированный AppLocalizations.localizationsDelegates тянет делегаты
  // flutter_localizations, а виджеты material_ui ищут свои — берём их из material_ui.
  // liquid_glass_widgets строит диалоги на фреймворковом flutter/cupertino —
  // ему нужны CupertinoLocalizations из flutter_localizations, а не из cupertino_ui.
  static final delegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
    framework.GlobalCupertinoLocalizations.delegate,
  ];

  static const supportedLocales = AppLocalizations.supportedLocales;

  static Locale resolve(List<Locale>? preferred, Iterable<Locale> supported) {
    for (final locale in preferred ?? const <Locale>[]) {
      for (final candidate in supported) {
        if (candidate.languageCode == locale.languageCode) return candidate;
      }
    }
    return const Locale('ru');
  }
}
