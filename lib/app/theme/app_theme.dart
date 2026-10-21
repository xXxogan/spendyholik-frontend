import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/colors_manager.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorsManager.build(brightness);

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: "Roboto Flex",
    );
  }
}
