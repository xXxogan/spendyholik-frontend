import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

class TransactionTypeChips extends StatelessWidget {
  const TransactionTypeChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// null — «Все».
  final TransactionType? selected;
  final ValueChanged<TransactionType?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = <TransactionType?, String>{
      null: l10n.transactionsFilterAll,
      TransactionType.expense: l10n.transactionsFilterExpense,
      TransactionType.income: l10n.transactionsFilterIncome,
      TransactionType.transfer: l10n.transactionsFilterTransfer,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final MapEntry(key: type, value: label) in labels.entries)
          ChoiceChip(
            label: Text(label),
            selected: type == selected,
            onSelected: (_) => onSelected(type),
          ),
      ],
    );
  }
}
