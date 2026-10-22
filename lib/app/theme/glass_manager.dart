import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

abstract final class GlassManager {
  // На Web пакет всё равно ограничивает качество уровнем standard (спайк S-01) —
  // задаём его явно, чтобы стекло выглядело одинаково на всех платформах.
  static GlassThemeData theme() => const GlassThemeData(
    light: GlassThemeVariant(quality: GlassQuality.standard),
    dark: GlassThemeVariant(quality: GlassQuality.standard),
  );
}
