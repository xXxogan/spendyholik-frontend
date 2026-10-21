import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';

@RoutePage()
class GeneralPage extends StatelessWidget {
  const GeneralPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        BaseLayout(
          children: [
            Row(
              mainAxisAlignment: .center,
              children: [
                Text("700 тыс. ₽", style: theme.textTheme.displayMedium),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
