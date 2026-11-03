import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.dart';
import 'package:spendyholik/app/theme/app_theme.dart';
import 'package:spendyholik/core/logger/talker_auto_route_observer.dart';
import 'package:spendyholik/features/settings/settings.dart';
import 'package:spendyholik/l10n/l10n.dart';
import 'package:talker/talker.dart';

class SpendyHolikApp extends StatefulWidget {
  const SpendyHolikApp({super.key});

  @override
  State<SpendyHolikApp> createState() => _SpendyHolikAppState();
}

class _SpendyHolikAppState extends State<SpendyHolikApp> {
  late final _routerConfig = getIt<AppRouter>().config(
    navigatorObservers: () => [TalkerAutoRouteObserver(getIt<Talker>())],
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<SettingsCubit>(),
      child: BlocSelector<SettingsCubit, AppSettings, AppThemeMode>(
        selector: (settings) => settings.themeMode,
        builder: (context, themeMode) => MaterialApp.router(
          onGenerateTitle: (context) => context.l10n.appTitle,
          builder: (_, child) => Material(type: .transparency, child: child),
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
    );
  }
}
