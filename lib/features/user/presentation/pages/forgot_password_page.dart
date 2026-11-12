import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/user/presentation/cubit/forgot_password_cubit.dart';
import 'package:spendyholik/features/user/presentation/cubit/register_cubit.dart';
import 'package:spendyholik/features/user/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ForgotPasswordCubit>(),
      child: const ForgotPasswordView(),
    );
  }
}

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<ForgotPasswordCubit>();

    return BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
      listenWhen: (previous, current) =>
          previous.step != current.step || previous.failure != current.failure,
      listener: (context, state) {
        if (state.step == ForgotPasswordStep.done) {
          showAppToast(context, l10n.forgotPasswordDone);
          context.router.replaceAll([const LoginRoute()]);
        } else if (state.failure case final failure?) {
          showAppToast(context, failureMessage(l10n, failure), error: true);
        }
      },
      builder: (context, state) {
        String? error(ForgotPasswordField field) =>
            switch (state.fieldErrors[field]) {
              final error? => fieldErrorText(l10n, error),
              null => null,
            };
        final busy = state.status == .submitting;
        final onCodeStep = state.step != ForgotPasswordStep.email;

        Widget submitLabel(String text) => busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(text);

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
              l10n.forgotPasswordTitle,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: .w700),
            ),
            const SizedBox(height: 4),
            Text(
              onCodeStep ? l10n.forgotPasswordSent : l10n.forgotPasswordHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (!onCodeStep) ...[
              TextField(
                onChanged: cubit.emailChanged,
                onSubmitted: (_) => cubit.requestCode(),
                keyboardType: .emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: l10n.authEmail,
                  errorText: error(.email),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy ? null : cubit.requestCode,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: submitLabel(l10n.forgotPasswordGetCode),
              ),
            ] else
              Column(
                crossAxisAlignment: .stretch,
                spacing: 14,
                children: [
                  Center(
                    child: AppCodeField(
                      onChanged: cubit.codeChanged,
                      onCompleted: cubit.codeChanged,
                      errorText: error(.code),
                    ),
                  ),
                  ResendCodeButton(
                    resendIn: state.resendIn,
                    onPressed: cubit.resend,
                  ),
                  PasswordField(
                    label: l10n.profileNewPassword,
                    hint: l10n.registerPasswordHint(
                      RegisterCubit.minPasswordLength,
                    ),
                    onChanged: cubit.newPasswordChanged,
                    onSubmitted: (_) => cubit.submit(),
                    autofillHints: const [AutofillHints.newPassword],
                    errorText: error(.newPassword),
                  ),
                  const SizedBox(height: 6),
                  FilledButton(
                    onPressed: busy ? null : cubit.submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: submitLabel(l10n.passwordChangeSubmit),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
