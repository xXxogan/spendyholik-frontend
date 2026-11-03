import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/l10n/l10n.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    required this.onChanged,
    this.hint,
    this.errorText,
    this.autofillHints,
    this.onSubmitted,
  });

  final String label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  var _hidden = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return TextField(
      obscureText: _hidden,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          icon: Icon(
            _hidden ? Icons.visibility_outlined : Icons.visibility_off,
          ),
          tooltip: _hidden ? l10n.authShowPassword : l10n.authHidePassword,
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
    );
  }
}
