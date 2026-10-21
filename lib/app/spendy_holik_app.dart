import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/router/app_router.dart';
import 'package:spendyholik/app/theme/app_theme.dart';

class SpendyHolikApp extends StatelessWidget {
  SpendyHolikApp({super.key});

  final _router = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      builder: (_, child) => Material(type: .transparency, child: child),
      theme: AppTheme.dark(),
      routerConfig: _router.config(),
    );
  }
}
