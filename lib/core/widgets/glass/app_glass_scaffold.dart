import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/large_title_controllers.dart';
import 'package:spendyholik/core/widgets/glass/large_title_scope.dart';
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
    this.floatingButton,
  });

  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final bool largeTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? bottomBar;

  /// Справа внизу над контентом: над таб-баром, если он есть.
  final Widget? floatingButton;

  @override
  State<AppGlassScaffold> createState() => _AppGlassScaffoldState();
}

class _AppGlassScaffoldState extends State<AppGlassScaffold> {
  static const _toolbarHeight = 44.0;

  final _largeTitles = LargeTitleControllers();

  @override
  void dispose() {
    _largeTitles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leftInset = ShellScope.leftInsetOf(context);
    final barTop = ShellScope.appBarTopOf(context);
    final title = widget.title;

    return GlassScaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      appBarHeight: _toolbarHeight + barTop,
      appBar: Padding(
        padding: .only(left: leftInset, top: barTop),
        child: GlassAppBar(
          toolbarHeight: _toolbarHeight,
          padding: const .only(left: 8, right: 16),
          title: widget.titleWidget ?? (title == null ? null : Text(title)),
          largeTitleController: widget.largeTitle && title != null
              ? _largeTitles.of(title)
              : null,
          leading: widget.leading,
          actions: widget.actions,
          centerTitle: widget.centerTitle,
        ),
      ),
      body: LargeTitleScope(
        controllers: _largeTitles,
        child: Padding(
          padding: .only(left: leftInset),
          child: widget.body,
        ),
      ),
      bottomBar: widget.bottomBar,
      bodyOverlays: [
        if (widget.floatingButton case final button?)
          Positioned(
            right: 16,
            bottom: _floatingBottom(context),
            child: button,
          ),
      ],
    );
  }

  /// Над таб-баром по тем же правилам, по которым его ставит GlassScaffold:
  /// у нижнего края, safe area снизу — только на Android.
  double _floatingBottom(BuildContext context) {
    final bar = widget.bottomBar;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    if (bar == null) return safeBottom + 16;
    final barHeight = bar is PreferredSizeWidget
        ? bar.preferredSize.height
        : 60.0;
    final barSafeArea = Theme.of(context).platform == TargetPlatform.android
        ? safeBottom
        : 0.0;
    return barHeight + barSafeArea + 12;
  }
}
