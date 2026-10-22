import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/colors_manager.dart';

abstract final class AppTheme {
  static const fontFamily = 'Roboto Flex';

  static ThemeData light() => FlexThemeData.light(
    keyColors: ColorsManager.keyColors,
    tones: ColorsManager.tones(Brightness.light),
    fontFamily: fontFamily,
  );

  static ThemeData dark() => FlexThemeData.dark(
    keyColors: ColorsManager.keyColors,
    tones: ColorsManager.tones(Brightness.dark),
    fontFamily: fontFamily,
  );
}
