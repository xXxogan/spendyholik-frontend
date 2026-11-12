import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

enum AppThemeMode { system, light, dark }

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default(true) bool pushEnabled,
  }) = _AppSettings;
}
