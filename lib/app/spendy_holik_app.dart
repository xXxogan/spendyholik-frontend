import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/app/router/guards.dart';
import 'package:spendyholik/app/theme/app_theme.dart';
import 'package:spendyholik/core/logger/talker_auto_route_observer.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/settings/settings.dart';
import 'package:spendyholik/features/user/user.dart';
import 'package:spendyholik/l10n/l10n.dart';
import 'package:talker/talker.dart';

class SpendyHolikApp extends StatefulWidget {
  const SpendyHolikApp({super.key});

  @override
  State<SpendyHolikApp> createState() => _SpendyHolikAppState();
}

class _SpendyHolikAppState extends State<SpendyHolikApp> {
  late final _routerConfig = getIt<AppRouter>().config(
    deepLinkBuilder: (link) => switch (deepLinkNext(link.uri.toString())) {
      final next? => DeepLink([SplashRoute(next: next)]),
      null => link,
    },
    navigatorObservers: () => [TalkerAutoRouteObserver(getIt<Talker>())],
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<SettingsCubit>()),
        BlocProvider.value(value: getIt<SessionCubit>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<SessionCubit, SessionState>(
            // Выход откуда угодно — на вход; стек сбрасывается, «Назад» во
            // вкладки не ведёт.
            listenWhen: (previous, current) =>
                previous is SessionAuthenticated &&
                current is SessionUnauthenticated,
            listener: (_, _) =>
                getIt<AppRouter>().replaceAll([const LoginRoute()]),
          ),
          BlocListener<SessionCubit, SessionState>(
            // Подтверждённая почта стала неподтверждённой (сменили email, сервер
            // ответил 403) — на экран кода. Вход, регистрацию и старт ведут
            // Splash и guard'ы — здесь их не дублируем.
            listenWhen: (previous, current) =>
                previous is SessionAuthenticated &&
                previous.user.emailVerified &&
                current is SessionAuthenticated &&
                !current.user.emailVerified,
            listener: (_, _) =>
                getIt<AppRouter>().replaceAll([const EmailConfirmRoute()]),
          ),
        ],
        child: BlocSelector<SettingsCubit, AppSettings, AppThemeMode>(
          selector: (settings) => settings.themeMode,
          builder: (context, themeMode) => MaterialApp.router(
            onGenerateTitle: (context) => context.l10n.appTitle,
            builder: (_, child) =>
                BlocSelector<SessionCubit, SessionState, Currency>(
                  selector: (state) => switch (state) {
                    SessionAuthenticated(:final user) =>
                      user.baseCurrency ?? Currency.rub,
                    _ => Currency.rub,
                  },
                  builder: (_, currency) => CurrencyScope(
                    currency: currency,
                    child: Material(type: .transparency, child: child),
                  ),
                ),
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: switch (themeMode) {
              AppThemeMode.system => ThemeMode.system,
              AppThemeMode.light => ThemeMode.light,
              AppThemeMode.dark => ThemeMode.dark,
            },
            localizationsDelegates: AppLocalizationsSetup.delegates,
            supportedLocales: AppLocalizationsSetup.supportedLocales,
            localeListResolutionCallback: AppLocalizationsSetup.resolve,
            routerConfig: _routerConfig,
          ),
        ),
      ),
    );
  }
}
