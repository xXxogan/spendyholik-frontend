import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/guards.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/user/presentation/cubit/session_cubit.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Пользователь приходит в сессию через userChanges, а не вместе с ответом
/// входа — ждём его, иначе guard Главной вернёт на вход. [until] — какого
/// состояния ждать (после ввода кода — подтверждённой почты, иначе Splash
/// вернёт на экран кода).
Future<void> leaveAuth(
  BuildContext context, {
  bool Function(SessionState state)? until,
}) async {
  final state = await getIt<SessionCubit>().waitFor(
    until ?? (s) => s is SessionAuthenticated,
  );
  if (!context.mounted) return;
  if (state == null) {
    showAppToast(
      context,
      failureMessage(context.l10n, const UnknownFailure()),
      error: true,
    );
    return;
  }
  await context.router.replaceAll([splashRoute(state)!]);
}
