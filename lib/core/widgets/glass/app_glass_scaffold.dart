import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/large_title.dart';
import 'package:spendyholik/core/widgets/glass/shell_scope.dart';

/// [largeTitle] — iOS-заголовок: большой в контенте (`BaseLayout(largeTitle:)`
/// с тем же текстом), при прокрутке уходит, и в шапке появляется [title].
class AppGlassScaffold extends StatefulWidget {
  const AppGlassScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
    this.largeTitle = false,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.bottomBar,
  });

  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final bool largeTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? bottomBar;

  @override
  State<AppGlassScaffold> createState() => _AppGlassScaffoldState();
}

class _AppGlassScaffoldState extends State<AppGlassScaffold> {
  final _largeTitles = LargeTitleControllers();

  @override
  void dispose() {
    _largeTitles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leftInset = ShellScope.leftInsetOf(context);
    final title = widget.title;

    return GlassScaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      appBar: Padding(
        padding: EdgeInsets.only(left: leftInset),
        child: GlassAppBar(
          title: widget.titleWidget ?? (title == null ? null : Text(title)),
          largeTitleController: widget.largeTitle && title != null ? _largeTitles.of(title) : null,
          leading: widget.leading,
          actions: widget.actions,
          centerTitle: widget.centerTitle,
        ),
      ),
      body: LargeTitleScope(
        controllers: _largeTitles,
        child: Padding(padding: EdgeInsets.only(left: leftInset), child: widget.body),
      ),
      bottomBar: widget.bottomBar,
    );
  }
}
