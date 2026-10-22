import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/layout/window_size.dart';

const _expandedWidth = 480.0;

/// Через корневой навигатор: иначе затемнение не накрывает боковую панель —
/// она лежит над навигатором контента.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final horizontal = context.windowSize == WindowSize.expanded
      ? (width - _expandedWidth) / 2
      : 8.0;

  return glass.GlassSheet.show<T>(
    context: context,
    useRootNavigator: true,
    margin: .fromLTRB(horizontal, 8, horizontal, 8),
    padding: const .fromLTRB(20, 4, 20, 20),
    builder: builder,
  );
}
