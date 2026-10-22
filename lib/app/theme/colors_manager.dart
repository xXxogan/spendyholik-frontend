import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';

abstract final class ColorsManager {
  static const keyColors = FlexKeyColors(keyPrimary: AppColors.seedColor);

  static FlexTones tones(Brightness brightness) =>
      FlexTones.material(brightness).monochromeSurfaces();
}
