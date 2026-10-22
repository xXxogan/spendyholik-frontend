import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.dart';
import 'package:spendyholik/app/theme/app_theme.dart';
import 'package:spendyholik/l10n/l10n.dart';
import 'package:talker_flutter/talker_flutter.dart';

class SpendyHolikApp extends StatefulWidget {
  const SpendyHolikApp({super.key});

  @override
  State<SpendyHolikApp> createState() => _SpendyHolikAppState();
}

class _SpendyHolikAppState extends State<SpendyHolikApp> {
  late final _routerConfig = getIt<AppRouter>().config(
    navigatorObservers: () => [TalkerRouteObserver(getIt<Talker>())],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      builder: (_, child) => Material(type: .transparency, child: child),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizationsSetup.delegates,
      supportedLocales: AppLocalizationsSetup.supportedLocales,
      localeListResolutionCallback: AppLocalizationsSetup.resolve,
      routerConfig: _routerConfig,
    );
  }
}
