import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/shell_scope.dart';

class AppGlassScaffold extends StatelessWidget {
  const AppGlassScaffold({
    super.key,
    required this.body,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.bottomBar,
  });

  final Widget body;
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final leftInset = ShellScope.leftInsetOf(context);

    return GlassScaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      appBar: Padding(
        padding: EdgeInsets.only(left: leftInset),
        child: GlassAppBar(
          title: title,
          leading: leading,
          actions: actions,
          centerTitle: centerTitle,
        ),
      ),
      body: Padding(padding: EdgeInsets.only(left: leftInset), child: body),
      bottomBar: bottomBar,
    );
  }
}
