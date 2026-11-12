import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

enum AppThemeMode { system, light, dark }

enum AppLanguage {
  system,
  ru,
  en;

  /// `null` — язык системы; запасной ru выбирает `AppLocalizationsSetup.resolve`.
  Locale? get locale => switch (this) {
    system => null,
    ru => const Locale('ru'),
    en => const Locale('en'),
  };
}

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default(AppLanguage.system) AppLanguage language,
    @Default(true) bool pushEnabled,
  }) = _AppSettings;
}
