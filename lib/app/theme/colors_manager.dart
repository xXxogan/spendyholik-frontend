// color_scheme_builder.dart
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';

class ColorsManager {
  static ColorScheme build(Brightness brightness) {
    return SeedColorScheme.fromSeeds(
      brightness: brightness,
      primaryKey: AppColors.seedColor,
      tones: FlexTones.material(brightness).monochromeSurfaces(),
    );
  }
}
