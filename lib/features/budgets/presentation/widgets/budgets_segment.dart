import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/l10n/l10n.dart';

enum BudgetsTab { budgets, goals }

class BudgetsSegment extends StatelessWidget {
  const BudgetsSegment({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final BudgetsTab selected;
  final ValueChanged<BudgetsTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SegmentedButton<BudgetsTab>(
      segments: [
        ButtonSegment(
          value: BudgetsTab.budgets,
          label: Text(l10n.budgetsSegmentBudgets),
        ),
        ButtonSegment(
          value: BudgetsTab.goals,
          label: Text(l10n.budgetsSegmentGoals),
        ),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onSelected(selection.first),
    );
  }
}
