import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:spendyholik/l10n/l10n.dart';

class AccountsFilterChips extends StatelessWidget {
  const AccountsFilterChips({super.key, required this.selected, required this.onSelected});

  final AccountsFilter? selected;
  final ValueChanged<AccountsFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = {
      AccountsFilter.all: l10n.accountsFilterAll,
      AccountsFilter.active: l10n.accountsFilterActive,
      AccountsFilter.archived: l10n.accountsFilterArchived,
    };

    return Wrap(
      spacing: 8,
      children: [
        for (final MapEntry(key: filter, value: label) in labels.entries)
          ChoiceChip(
            label: Text(label),
            selected: filter == selected,
            onSelected: (_) => onSelected(filter),
          ),
      ],
    );
  }
}
