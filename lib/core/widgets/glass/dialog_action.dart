import 'package:spendyholik/core/widgets/glass/dialog_emphasis.dart';
import 'package:material_ui/material_ui.dart';

class DialogAction {
  const DialogAction({
    required this.label,
    required this.onPressed,
    this.emphasis = DialogEmphasis.none,
  });

  final String label;
  final VoidCallback onPressed;
  final DialogEmphasis emphasis;
}
