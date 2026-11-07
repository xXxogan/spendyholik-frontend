import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/app_glass_dialog.dart';
import 'package:spendyholik/core/widgets/glass/dialog_action.dart';
import 'package:spendyholik/core/widgets/glass/dialog_emphasis.dart';

/// Свой диалог вместо GlassDialog: тот всегда ставит две кнопки в ряд по половине
/// ширины, и длинная подпись («Архивировать») не помещается.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required String cancelLabel,
  String? message,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.38),
    builder: (dialogContext) => AppGlassDialog(
      title: title,
      message: message,
      actions: [
        DialogAction(
          label: cancelLabel,
          onPressed: () => Navigator.pop(dialogContext, false),
        ),
        DialogAction(
          label: confirmLabel,
          emphasis: destructive
              ? DialogEmphasis.destructive
              : DialogEmphasis.primary,
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
