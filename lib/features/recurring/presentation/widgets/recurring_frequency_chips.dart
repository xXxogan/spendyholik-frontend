import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/features/recurring/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

class RecurringFrequencyChips extends StatelessWidget {
  const RecurringFrequencyChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final RecurrenceFrequency selected;
  final ValueChanged<RecurrenceFrequency> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final frequency in RecurrenceFrequency.values)
          ChoiceChip(
            label: Text(switch (frequency) {
              RecurrenceFrequency.monthly => l10n.recurringFrequencyMonthly,
              RecurrenceFrequency.weekly => l10n.recurringFrequencyWeekly,
              RecurrenceFrequency.yearly => l10n.recurringFrequencyYearly,
            }),
            selected: frequency == selected,
            onSelected: (_) => onSelected(frequency),
          ),
      ],
    );
  }
}
