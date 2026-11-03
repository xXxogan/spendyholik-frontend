import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

class BudgetPeriodChips extends StatelessWidget {
  const BudgetPeriodChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final BudgetPeriod selected;
  final ValueChanged<BudgetPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final period in BudgetPeriod.values)
          ChoiceChip(
            label: Text(switch (period) {
              BudgetPeriod.monthly => l10n.budgetPeriodMonthly,
              BudgetPeriod.weekly => l10n.budgetPeriodWeekly,
              BudgetPeriod.once => l10n.budgetPeriodOnce,
            }),
            selected: period == selected,
            onSelected: (_) => onSelected(period),
          ),
      ],
    );
  }
}
