import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/accounts_cubit.dart';

/// Выбор счёта для форм операций, целей, долгов.
class AccountPicker extends StatelessWidget {
  const AccountPicker({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.errorText,
  });

  final String label;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AccountsCubit>()..load(),
      child: BlocBuilder<AccountsCubit, AccountsState>(
        builder: (context, state) {
          // Архивные не предлагаем, но уже выбранный оставляем: иначе правка
          // старой операции по архивному счёту не сохранится.
          final accounts = switch (state) {
            AccountsLoaded(:final accounts) => [
              for (final account in accounts)
                if (!account.isArchived || account.id == selected) account,
            ],
            _ => null,
          };
          // Значение вне списка роняет Dropdown — пока счета грузятся, его нет.
          final value =
              accounts != null &&
                  accounts.any((account) => account.id == selected)
              ? selected
              : null;

          return DropdownButtonFormField<String>(
            key: ValueKey((value, accounts?.length)),
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(labelText: label, errorText: errorText),
            items: [
              for (final account in accounts ?? const [])
                DropdownMenuItem(value: account.id, child: Text(account.name)),
            ],
            onChanged: accounts == null ? null : onSelected,
          );
        },
      ),
    );
  }
}
