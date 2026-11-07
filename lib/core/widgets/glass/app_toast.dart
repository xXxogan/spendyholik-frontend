import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/app_toast_overlay.dart';
import 'package:spendyholik/core/widgets/glass/shell_scope.dart';

/// Свой показ вместо `GlassToast.show`: тот растягивает тост от края до края
/// окна, а оверлей страницы лежит под боковой панелью — тост уходит под неё.
void showAppToast(BuildContext context, String message, {bool error = false}) {
  // Читаем сейчас: страница часто сразу уходит назад, а builder записи
  // вызывается и после — с context закрытой страницы.
  final leftInset = ShellScope.leftInsetOf(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => AppToastOverlay(
      message: message,
      type: error ? GlassToastType.error : GlassToastType.success,
      leftInset: leftInset,
      onDismissed: entry.remove,
    ),
  );
  Overlay.of(context).insert(entry);
}
