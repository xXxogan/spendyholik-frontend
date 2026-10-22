import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/large_title_scope.dart';

class LargeTitleSliver extends StatelessWidget {
  const LargeTitleSliver({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final controllers = LargeTitleScope.maybeOf(context);
    if (controllers == null) return const SliverToBoxAdapter();

    return GlassLargeTitle(
      text: title,
      controller: controllers.of(title),
      padding: const .only(bottom: 8),
    );
  }
}
