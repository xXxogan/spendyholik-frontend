import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

class AccountArchiveButton extends StatelessWidget {
  const AccountArchiveButton({super.key, required this.onArchive});

  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = AppColors.negative(Theme.of(context).brightness);

    return OutlinedButton.icon(
      icon: const Icon(Icons.archive_outlined),
      label: Text(l10n.accountArchiveAction),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
      ),
      onPressed: () async {
        final confirmed = await showAppConfirmDialog(
          context,
          title: l10n.accountArchiveConfirmTitle,
          message: l10n.accountArchiveConfirmMessage,
          confirmLabel: l10n.accountArchiveConfirm,
          cancelLabel: l10n.commonCancel,
          destructive: true,
        );
        if (confirmed) onArchive();
      },
    );
  }
}
