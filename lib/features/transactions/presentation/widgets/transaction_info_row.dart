import 'package:material_ui/material_ui.dart';

class TransactionInfoRow extends StatelessWidget {
  const TransactionInfoRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: .start,
      spacing: 16,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(value, textAlign: .end, style: theme.textTheme.bodyLarge),
        ),
      ],
    );
  }
}
