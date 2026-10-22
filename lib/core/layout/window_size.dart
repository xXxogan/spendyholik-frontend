import 'package:material_ui/material_ui.dart';

abstract final class Breakpoints {
  static const medium = 720.0;
  static const expanded = 1080.0;
  static const contentMaxWidth = 1200.0;
}

enum WindowSize {
  compact,
  medium,
  expanded;

  static WindowSize fromWidth(double width) {
    if (width >= Breakpoints.expanded) return expanded;
    if (width >= Breakpoints.medium) return medium;
    return compact;
  }
}

extension WindowSizeX on BuildContext {
  WindowSize get windowSize => WindowSize.fromWidth(MediaQuery.sizeOf(this).width);
}
