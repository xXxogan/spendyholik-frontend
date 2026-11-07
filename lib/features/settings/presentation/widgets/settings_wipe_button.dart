import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/settings/presentation/cubit/data_reset_cubit.dart';
import 'package:spendyholik/l10n/l10n.dart';

class SettingsWipeButton extends StatelessWidget {
  const SettingsWipeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final negative = AppColors.negative(Theme.of(context).brightness);
    final submitting =
        context.watch<DataResetCubit>().state.status == FormStatus.submitting;

    return OutlinedButton.icon(
      icon: const Icon(Icons.delete_outline),
      label: Text(l10n.settingsWipe),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: negative,
        side: BorderSide(color: negative),
      ),
      onPressed: submitting
          ? null
          : () async {
              final cubit = context.read<DataResetCubit>();
              final confirmed = await showAppConfirmDialog(
                context,
                title: l10n.settingsWipeConfirmTitle,
                message: l10n.settingsWipeConfirmMessage,
                confirmLabel: l10n.settingsWipeConfirm,
                cancelLabel: l10n.commonCancel,
                destructive: true,
              );
              if (confirmed) await cubit.wipe();
            },
    );
  }
}
