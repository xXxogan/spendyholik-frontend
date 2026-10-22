import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/l10n/l10n.dart';

class AccountUnarchiveButton extends StatelessWidget {
  const AccountUnarchiveButton({super.key, required this.onUnarchive});

  final VoidCallback onUnarchive;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.unarchive_outlined),
      label: Text(context.l10n.accountUnarchiveAction),
      onPressed: onUnarchive,
    );
  }
}
