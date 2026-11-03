import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/guards.dart';
import 'package:spendyholik/features/user/presentation/cubit/session_cubit.dart';

/// Пользователь приходит в сессию через userChanges, а не вместе с ответом
/// входа — ждём его, иначе guard Главной вернёт на вход.
Future<void> leaveAuth(BuildContext context) async {
  final session = getIt<SessionCubit>();
  final state = session.state is SessionAuthenticated
      ? session.state
      : await session.stream.firstWhere((s) => s is SessionAuthenticated);
  if (context.mounted) await context.router.replaceAll([splashRoute(state)!]);
}
