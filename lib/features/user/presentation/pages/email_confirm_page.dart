import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/user/presentation/cubit/email_confirm_cubit.dart';
import 'package:spendyholik/features/user/presentation/cubit/session_cubit.dart';
import 'package:spendyholik/features/user/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class EmailConfirmPage extends StatelessWidget {
  const EmailConfirmPage({super.key});

  @override
  Widget build(BuildContext context) {
    final email = switch (getIt<SessionCubit>().state) {
      SessionAuthenticated(:final user) => user.email,
      _ => '',
    };
    return BlocProvider(
      create: (_) => getIt<EmailConfirmCubit>()..init(email),
      child: const EmailConfirmView(),
    );
  }
}

class EmailConfirmView extends StatefulWidget {
  const EmailConfirmView({super.key});

  @override
  State<EmailConfirmView> createState() => _EmailConfirmViewState();
}

class _EmailConfirmViewState extends State<EmailConfirmView> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<EmailConfirmCubit>();

    return BlocConsumer<EmailConfirmCubit, EmailConfirmState>(
      listener: (context, state) {
        // Неверный код Cubit сбрасывает — поле очищается вместе с ним.
        if (state.code.isEmpty && _code.text.isNotEmpty) _code.clear();
        if (state.status == FormStatus.success) {
          leaveAuth(
            context,
            until: (s) => s is SessionAuthenticated && s.user.emailVerified,
          );
        }
      },
      builder: (context, state) {
        final busy = state.status == .submitting;
        final failure = state.failure;

        return AuthLayout(
          children: [
            Text(
              l10n.emailConfirmTitle,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: .w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emailConfirmSubtitle(state.email),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: AppCodeField(
                controller: _code,
                enabled: !busy,
                onChanged: cubit.codeChanged,
                onCompleted: cubit.submit,
                errorText: switch (state.codeError) {
                  final error? => fieldErrorText(l10n, error),
                  null => null,
                },
              ),
            ),
            if (failure != null) ...[
              const SizedBox(height: 12),
              Text(
                failureMessage(l10n, failure),
                textAlign: .center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (busy)
              const Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              ResendCodeButton(
                resendIn: state.resendIn,
                onPressed: cubit.resend,
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: cubit.signOut,
              child: Text(l10n.emailConfirmSignOut),
            ),
          ],
        );
      },
    );
  }
}
