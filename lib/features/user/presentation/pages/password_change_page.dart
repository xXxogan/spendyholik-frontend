import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/user/presentation/cubit/password_change_cubit.dart';
import 'package:spendyholik/features/user/presentation/cubit/register_cubit.dart';
import 'package:spendyholik/features/user/presentation/cubit/session_cubit.dart';
import 'package:spendyholik/features/user/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class PasswordChangePage extends StatelessWidget {
  const PasswordChangePage({super.key});

  @override
  Widget build(BuildContext context) {
    final email = switch (getIt<SessionCubit>().state) {
      SessionAuthenticated(:final user) => user.email,
      _ => '',
    };
    return BlocProvider(
      create: (_) => getIt<PasswordChangeCubit>(),
      child: PasswordChangeView(email: email),
    );
  }
}

class PasswordChangeView extends StatelessWidget {
  const PasswordChangeView({super.key, required this.email});

  /// Куда уйдёт код — показываем, чтобы пользователь знал, какой ящик открыть.
  final String email;

  static const _formMaxWidth = 560.0;
  static const _fallback = ProfileEditRoute();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<PasswordChangeCubit>();
    final title = l10n.passwordChangeTitle;

    return BlocConsumer<PasswordChangeCubit, PasswordChangeState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.failure != current.failure,
      listener: (context, state) {
        if (state.status == FormStatus.success) {
          showAppToast(context, l10n.passwordChanged);
          navigateBack(context.router, _fallback);
        } else if (state.failure case final failure?) {
          showAppToast(context, failureMessage(l10n, failure), error: true);
        }
      },
      builder: (context, state) {
        String? error(PasswordChangeField field) =>
            switch (state.fieldErrors[field]) {
              final error? => fieldErrorText(l10n, error),
              null => null,
            };
        final busy = state.status == .submitting;

        return AppGlassScaffold(
          leading: const AppBackButton(fallback: _fallback),
          title: title,
          largeTitle: true,
          body: BaseLayout.slivers(
            largeTitle: title,
            slivers: [
              ContentSliverPadding(
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _formMaxWidth,
                      ),
                      child: Padding(
                        padding: const .only(top: 12, bottom: 120),
                        child: Column(
                          crossAxisAlignment: .stretch,
                          spacing: 16,
                          children: [
                            Text(
                              l10n.passwordChangeHint(email),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (!state.codeSent)
                              FilledButton(
                                onPressed: cubit.sendCode,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                ),
                                child: Text(l10n.passwordChangeSendCode),
                              )
                            else ...[
                              Center(
                                child: AppCodeField(
                                  onChanged: cubit.codeChanged,
                                  onCompleted: cubit.codeChanged,
                                  errorText: error(.code),
                                ),
                              ),
                              ResendCodeButton(
                                resendIn: state.resendIn,
                                onPressed: cubit.sendCode,
                              ),
                              PasswordField(
                                label: l10n.profileNewPassword,
                                hint: l10n.registerPasswordHint(
                                  RegisterCubit.minPasswordLength,
                                ),
                                onChanged: cubit.newPasswordChanged,
                                onSubmitted: (_) => cubit.submit(),
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                errorText: error(.newPassword),
                              ),
                              FilledButton(
                                onPressed: busy ? null : cubit.submit,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                ),
                                child: busy
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(l10n.passwordChangeSubmit),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
