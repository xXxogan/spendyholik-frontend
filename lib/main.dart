import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/spendy_holik_app.dart';
import 'package:spendyholik/app/theme/glass_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LiquidGlassWidgets.initialize();

  runApp(
    LiquidGlassWidgets.wrap(
      child: SpendyHolikApp(),
      brightnessResolver: Theme.maybeBrightnessOf,
      theme: GlassManager.build(),
      adaptiveQuality: true,
    ),
  );
}
