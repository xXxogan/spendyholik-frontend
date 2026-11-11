import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Согласие на обработку персональных данных (152-ФЗ, ст. 9): отдельная
/// галочка, не отмечена заранее, со ссылкой на текст политики.
class ConsentCheckbox extends StatelessWidget {
  const ConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onPolicyTap,
    this.errorText,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPolicyTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final error = errorText;

    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          crossAxisAlignment: .start,
          children: [
            Checkbox(
              value: value,
              isError: error != null,
              onChanged: (checked) => onChanged(checked ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const .only(top: 12),
                child: Wrap(
                  children: [
                    Text(l10n.registerConsent),
                    InkWell(
                      onTap: onPolicyTap,
                      child: Text(
                        l10n.registerConsentPolicy,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: .underline,
                          decorationColor: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const .only(left: 12),
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
