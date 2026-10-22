import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/dialog_action.dart';
import 'package:spendyholik/core/widgets/glass/dialog_action_button.dart';

class AppGlassDialog extends StatelessWidget {
  const AppGlassDialog({
    super.key,
    required this.title,
    required this.actions,
    this.message,
  });

  final String title;
  final String? message;
  final List<DialogAction> actions;

  static const _maxWidth = 320.0;
  static const _padding = 20.0;
  static const _gap = 8.0;
  static const buttonHorizontalPadding = 16.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.titleSmall!;

    return Center(
      child: Padding(
        padding: const .all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: GlassCard(
            useOwnLayer: true,
            padding: const .all(_padding),
            child: AdaptiveLiquidGlassLayer(
              settings: const LiquidGlassSettings(),
              child: Column(
                mainAxisSize: .min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                    textAlign: .center,
                  ),
                  if (message case final message?) ...[
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: .center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final slot =
                          (constraints.maxWidth - _gap * (actions.length - 1)) /
                          actions.length;
                      final fitsInRow = actions.every(
                        (action) =>
                            _textWidth(context, action.label, labelStyle) +
                                buttonHorizontalPadding * 2 <=
                            slot,
                      );
                      final buttons = [
                        for (final action in actions)
                          DialogActionButton(action: action, style: labelStyle),
                      ];

                      return fitsInRow
                          ? Row(
                              children: [
                                for (var i = 0; i < buttons.length; i++) ...[
                                  if (i > 0) const SizedBox(width: _gap),
                                  Expanded(child: buttons[i]),
                                ],
                              ],
                            )
                          // Как в iOS: основное действие сверху, отмена снизу.
                          : Column(
                              crossAxisAlignment: .stretch,
                              children: [
                                for (
                                  var i = buttons.length - 1;
                                  i >= 0;
                                  i--
                                ) ...[
                                  buttons[i],
                                  if (i > 0) const SizedBox(height: _gap),
                                ],
                              ],
                            );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _textWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}
