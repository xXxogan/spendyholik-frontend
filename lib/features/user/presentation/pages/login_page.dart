import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/user/presentation/cubit/login_cubit.dart';
import 'package:spendyholik/features/user/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LoginCubit>(),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<LoginCubit>();

    return BlocConsumer<LoginCubit, LoginState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == FormStatus.success) leaveAuth(context);
      },
      builder: (context, state) {
        String? error(LoginField field) => switch (state.fieldErrors[field]) {
          final error? => fieldErrorText(l10n, error),
          null => null,
        };
        final busy = state.status == .submitting;

        return AuthLayout(
          children: [
            Align(
              alignment: .centerLeft,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: .circular(18),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.loginTitle,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: .w700),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.loginSubtitle,
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
                    onChanged: cubit.passwordChanged,
                    onSubmitted: (_) => cubit.submit(),
                    autofillHints: const [AutofillHints.password],
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
                  : Text(l10n.loginSubmit),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: .center,
              children: [
                Text(
                  l10n.loginNoAccount,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: () => context.router.push(const RegisterRoute()),
                  child: Text(l10n.loginCreateAccount),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
