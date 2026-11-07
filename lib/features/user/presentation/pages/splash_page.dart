import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/guards.dart';
import 'package:spendyholik/features/user/presentation/cubit/session_cubit.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, @QueryParam('next') this.next});

  /// Адрес прямой ссылки: открывается вместо Главной, если сессия есть.
  final String? next;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _session = getIt<SessionCubit>();

  @override
  void initState() {
    super.initState();
    // Сессия могла восстановиться раньше, чем Splash построился.
    WidgetsBinding.instance.addPostFrameCallback((_) => _route(_session.state));
  }

  void _route(SessionState state) {
    if (!mounted) return;
    final target = splashRoute(state);
    if (target == null) return;
    final next = widget.next;
    if (next != null && canFollowNext(target, next)) {
      context.router.replacePath(next);
    } else {
      context.router.replaceAll([target]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<SessionCubit, SessionState>(
      bloc: _session,
      listener: (_, state) => _route(state),
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: .min,
            spacing: 24,
            children: [
              Text(
                context.l10n.appTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: .w700,
                ),
              ),
              const SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
