import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/user/presentation/cubit/profile_edit_cubit.dart';
import 'package:spendyholik/features/user/presentation/cubit/register_cubit.dart';
import 'package:spendyholik/features/user/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

class ProfileForm extends StatelessWidget {
  const ProfileForm({super.key, required this.state, required this.cubit});

  final ProfileEditState state;
  final ProfileEditCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    String? error(ProfileField field) => switch (state.fieldErrors[field]) {
      final error? => fieldErrorText(l10n, error),
      null => null,
    };

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        TextFormField(
          initialValue: state.name,
          onChanged: cubit.nameChanged,
          textCapitalization: .words,
          decoration: InputDecoration(
            labelText: l10n.registerName,
            errorText: error(.name),
          ),
        ),
        TextFormField(
          initialValue: state.email,
          onChanged: cubit.emailChanged,
          keyboardType: .emailAddress,
          decoration: InputDecoration(
            labelText: l10n.authEmail,
            errorText: error(.email),
          ),
        ),
        DropdownButtonFormField<Currency>(
          initialValue: state.currency,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.profileCurrency),
          items: [
            for (final currency in Currency.values)
              DropdownMenuItem(
                value: currency,
                child: Text(
                  '${currency.code} — ${currencyLabel(l10n, currency)}',
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) cubit.currencyChanged(value);
          },
        ),
        const SizedBox(height: 4),
        Text(l10n.profileChangePassword, style: theme.textTheme.titleMedium),
        PasswordField(
          label: l10n.profileCurrentPassword,
          onChanged: cubit.currentPasswordChanged,
          autofillHints: const [AutofillHints.password],
          errorText: error(.currentPassword),
        ),
        PasswordField(
          label: l10n.profileNewPassword,
          hint: l10n.registerPasswordHint(RegisterCubit.minPasswordLength),
          onChanged: cubit.newPasswordChanged,
          autofillHints: const [AutofillHints.newPassword],
          errorText: error(.newPassword),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: state.status == .submitting ? null : cubit.save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: state.status == .submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.commonSave),
        ),
      ],
    );
  }
}
