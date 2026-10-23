import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/spendy_holik_app.dart';
import 'package:spendyholik/app/theme/glass_manager.dart';
import 'package:spendyholik/core/logger/liquid_glass_talker_logger.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

void main() {
  // DI до зоны: обработчику зоны Talker нужен с первой же ошибки.
  configureDependencies();
  final talker = getIt<Talker>();

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    Bloc.observer = TalkerBlocObserver(
      talker: talker,
      settings: const TalkerBlocLoggerSettings(
        printStateFullData: false,
        printEventFullData: false,
        printTransitions: true,
        printChanges: true,
      ),
    );
    FlutterError.onError = (details) =>
        talker.handle(details.exception, details.stack);

    final glassLogger = getIt<LiquidGlassTalkerLogger>()..attach();
    await LiquidGlassWidgets.initialize();
    talker.info('App started');

    runApp(
      LiquidGlassWidgets.wrap(
        child: const SpendyHolikApp(),
        brightnessResolver: Theme.maybeBrightnessOf,
        theme: GlassManager.theme(),
        adaptiveQuality: true,
        adaptiveConfig: glassLogger.adaptiveConfig(),
      ),
    );
  }, talker.handle);
}
