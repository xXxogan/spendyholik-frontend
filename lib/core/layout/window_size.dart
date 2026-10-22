import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/layout/breakpoints.dart';

export 'breakpoints.dart';

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
  WindowSize get windowSize =>
      WindowSize.fromWidth(MediaQuery.sizeOf(this).width);
}
