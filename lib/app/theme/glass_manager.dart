import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/colors_manager.dart';

class GlassManager {
  static GlassThemeData build() {
    final lightScheme = ColorsManager.build(Brightness.light);
    final darkScheme = ColorsManager.build(Brightness.dark);

    return GlassThemeData(
      //   light: GlassThemeVariant(
      //     settings: GlassThemeSettings(
      //       glassColor: lightScheme.primary.withValues(alpha: 0.01),
      //     ),
      //     glowColors: GlassGlowColors(primary: lightScheme.primary),
      //     quality: GlassQuality.standard,
      //   ),
      //   dark: GlassThemeVariant(
      //     settings: GlassThemeSettings(
      //       glassColor: darkScheme.primary.withValues(alpha: 0.01),
      //     ),
      //     glowColors: GlassGlowColors(primary: darkScheme.primary),
      //     quality: GlassQuality.standard,
      //   ),
    );
  }
}
