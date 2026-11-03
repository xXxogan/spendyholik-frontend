import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

class DebtsDirectionSegment extends StatelessWidget {
  const DebtsDirectionSegment({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final DebtDirection selected;

  /// `null` — сегмент неактивен (направление правкой не меняется).
  final ValueChanged<DebtDirection>? onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SegmentedButton<DebtDirection>(
      segments: [
        ButtonSegment(value: .iOwe, label: Text(l10n.debtsIOwe)),
        ButtonSegment(value: .owedToMe, label: Text(l10n.debtsOwedToMe)),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: switch (onSelected) {
        final onSelected? => (selection) => onSelected(selection.first),
        null => null,
      },
    );
  }
}
