import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/spendy_holik_app.dart';
import 'package:spendyholik/app/theme/glass_manager.dart';
import 'package:spendyholik/core/logger/liquid_glass_talker_logger.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  configureDependencies();
  final talker = getIt<Talker>();
  Bloc.observer = TalkerBlocObserver(talker: talker);
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
}
