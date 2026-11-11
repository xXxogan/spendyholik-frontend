import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// «Отправить снова» с обратным отсчётом: сервер принимает новый код не раньше
/// чем через минуту.
class ResendCodeButton extends StatelessWidget {
  const ResendCodeButton({
    super.key,
    required this.resendIn,
    required this.onPressed,
  });

  final int resendIn;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final waiting = resendIn > 0;

    return TextButton(
      onPressed: waiting ? null : onPressed,
      child: Text(waiting ? l10n.codeResendIn(resendIn) : l10n.codeResend),
    );
  }
}
