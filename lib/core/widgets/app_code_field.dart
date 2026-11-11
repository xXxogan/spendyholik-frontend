import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pinput/pinput.dart';

/// Поле 6-значного кода из письма (подтверждение почты, смена и сброс пароля).
///
/// Настройки — из спайка S-04: у pinput нет фильтра цифр и выключена вставка из
/// меню по умолчанию; `onClipboardFound` не используем — он читает буфер сам при
/// каждом возврате в приложение (баннер iOS) и не проверяет, что там цифры.
class AppCodeField extends StatelessWidget {
  const AppCodeField({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.controller,
    this.errorText,
    this.enabled = true,
    this.autofocus = true,
  });

  static const length = 6;

  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final String? errorText;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final base = PinTheme(
      width: 48,
      height: 56,
      textStyle: textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: .circular(12),
        border: .all(color: scheme.outlineVariant),
      ),
    );
    final error = errorText;

    return Pinput(
      length: length,
      controller: controller,
      autofocus: autofocus,
      enabled: enabled,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      enableInteractiveSelection: true,
      onChanged: onChanged,
      onCompleted: onCompleted,
      forceErrorState: error != null,
      errorText: error,
      errorTextStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
      defaultPinTheme: base,
      focusedPinTheme: base.copyBorderWith(
        border: .all(color: scheme.primary, width: 2),
      ),
      errorPinTheme: base.copyBorderWith(
        border: .all(color: scheme.error, width: 2),
      ),
    );
  }
}
