import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/budgets/presentation/cubit/budget_form_cubit.dart';
import 'package:spendyholik/l10n/l10n.dart';

class BudgetDeleteButton extends StatelessWidget {
  const BudgetDeleteButton({
    super.key,
    required this.state,
    required this.cubit,
  });

  final BudgetFormState state;
  final BudgetFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final negative = AppColors.negative(Theme.of(context).brightness);

    return OutlinedButton.icon(
      icon: const Icon(Icons.delete_outline),
      label: Text(l10n.budgetDeleteAction),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: negative,
        side: BorderSide(color: negative),
      ),
      onPressed: state.status == .submitting
          ? null
          : () async {
              final confirmed = await showAppConfirmDialog(
                context,
                title: l10n.budgetDeleteConfirmTitle,
                message: l10n.budgetDeleteConfirmMessage,
                confirmLabel: l10n.budgetDeleteAction,
                cancelLabel: l10n.commonCancel,
                destructive: true,
              );
              if (confirmed) await cubit.delete();
            },
    );
  }
}
