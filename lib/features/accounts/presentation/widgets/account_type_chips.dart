import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/presentation/widgets/account_type_label.dart';
import 'package:spendyholik/l10n/l10n.dart';

class AccountTypeChips extends StatelessWidget {
  const AccountTypeChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AccountType selected;
  final ValueChanged<AccountType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in AccountType.values)
          ChoiceChip(
            label: Text(accountTypeLabel(context.l10n, type)),
            selected: type == selected,
            onSelected: (_) => onSelected(type),
          ),
      ],
    );
  }
}
