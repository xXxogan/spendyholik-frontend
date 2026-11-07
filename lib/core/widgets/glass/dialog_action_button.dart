import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/app_glass_dialog.dart';
import 'package:spendyholik/core/widgets/glass/dialog_action.dart';
import 'package:spendyholik/core/widgets/glass/dialog_emphasis.dart';

class DialogActionButton extends StatelessWidget {
  const DialogActionButton({
    super.key,
    required this.action,
    required this.style,
  });

  final DialogAction action;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (color, glow) = switch (action.emphasis) {
      DialogEmphasis.none => (colorScheme.onSurface, null),
      DialogEmphasis.primary => (
        colorScheme.primary,
        colorScheme.primary.withValues(alpha: 0.3),
      ),
      DialogEmphasis.destructive => (
        colorScheme.error,
        colorScheme.error.withValues(alpha: 0.3),
      ),
    };

    return GlassButton.custom(
      onTap: action.onPressed,
      label: action.label,
      height: 44,
      shape: const LiquidRoundedSuperellipse(borderRadius: 12),
      glowColor: glow,
      child: Padding(
        padding: const .symmetric(
          horizontal: AppGlassDialog.buttonHorizontalPadding,
        ),
        child: Text(
          action.label,
          style: style.copyWith(
            color: color,
            fontWeight: action.emphasis == DialogEmphasis.none ? null : .w700,
          ),
          textAlign: .center,
        ),
      ),
    );
  }
}
