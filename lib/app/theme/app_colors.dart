import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/models/entity_color.dart';

abstract final class AppColors {
  static const seedColor = Color(0xFFFA6BCA);

  static Color positive(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFF2E9E5B) : const Color(0xFF5FD38D);

  static Color negative(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFFD93A3A) : const Color(0xFFFF7A70);

  static Color warning(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFFD99A00) : const Color(0xFFFFC94D);

  static Color entity(EntityColor color, Brightness brightness) {
    final base = _entity[color]!;
    return brightness == Brightness.light ? base : Color.lerp(base, Colors.white, 0.25)!;
  }

  static const _entity = {
    EntityColor.pink: Color(0xFFE0559F),
    EntityColor.red: Color(0xFFE5484D),
    EntityColor.orange: Color(0xFFF08A24),
    EntityColor.yellow: Color(0xFFE2B714),
    EntityColor.green: Color(0xFF2FA36B),
    EntityColor.teal: Color(0xFF1AA3A3),
    EntityColor.blue: Color(0xFF3B6FE0),
    EntityColor.purple: Color(0xFF8B5CF6),
    EntityColor.gray: Color(0xFF7A808A),
  };
}
