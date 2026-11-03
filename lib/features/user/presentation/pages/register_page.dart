import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/user/presentation/cubit/register_cubit.dart';
import 'package:spendyholik/features/user/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RegisterCubit>(),
      child: const RegisterView(),
    );
  }
}

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<RegisterCubit>();

    return BlocConsumer<RegisterCubit, RegisterState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == FormStatus.success) leaveAuth(context);
      },
      builder: (context, state) {
        String? error(RegisterField field) =>
            switch (state.fieldErrors[field]) {
              final error? => fieldErrorText(l10n, error),
              null => null,
            };
        final busy = state.status == .submitting;

        return AuthLayout(
          children: [
            Align(
              alignment: .centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () =>
                    navigateBack(context.router, const LoginRoute()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.registerTitle,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: .w700),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.registerSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            AutofillGroup(
              child: Column(
                crossAxisAlignment: .stretch,
                spacing: 14,
                children: [
                  TextField(
                    onChanged: cubit.nameChanged,
                    textCapitalization: .words,
                    autofillHints: const [AutofillHints.givenName],
                    decoration: InputDecoration(
                      labelText: l10n.registerName,
                      errorText: error(.name),
                    ),
                  ),
                  TextField(
                    onChanged: cubit.emailChanged,
                    keyboardType: .emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: l10n.authEmail,
                      errorText: error(.email),
                    ),
                  ),
                  PasswordField(
                    label: l10n.authPassword,
                    hint: l10n.registerPasswordHint(
                      RegisterCubit.minPasswordLength,
                    ),
                    onChanged: cubit.passwordChanged,
                    onSubmitted: (_) => cubit.submit(),
                    autofillHints: const [AutofillHints.newPassword],
                    errorText: error(.password),
                  ),
                ],
              ),
            ),
            if (state.failure case final failure?) ...[
              const SizedBox(height: 12),
              Text(
                failureMessage(l10n, failure),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: busy ? null : cubit.submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.registerSubmit),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.registerTerms,
              textAlign: .center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}
