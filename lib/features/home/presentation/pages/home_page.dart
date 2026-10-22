import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/features/home/presentation/widgets/home_shell.dart';
import 'package:spendyholik/features/home/presentation/widgets/widgets.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoRouter(
      builder: (context, content) => HomeShell(content: content),
    );
  }
}
