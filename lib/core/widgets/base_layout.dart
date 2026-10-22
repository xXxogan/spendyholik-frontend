import 'package:spendyholik/core/widgets/glass/large_title_sliver.dart';
import 'package:spendyholik/core/widgets/glass/large_title_scope.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/content_sliver_padding.dart';
import 'package:spendyholik/core/widgets/glass/shell_scope.dart';

class BaseLayout extends StatelessWidget {
  const BaseLayout({
    super.key,
    required List<Widget> this.children,
    this.largeTitle,
  }) : slivers = null;

  const BaseLayout.slivers({
    super.key,
    required List<Widget> this.slivers,
    this.largeTitle,
  }) : children = null;

  final List<Widget>? children;
  final List<Widget>? slivers;

  /// Тот же текст, что `title` у `AppGlassScaffold(largeTitle: true)`.
  final String? largeTitle;

  @override
  Widget build(BuildContext context) {
    final largeTitle = this.largeTitle;

    return CustomScrollView(
      controller: largeTitle == null
          ? null
          : largeTitleScrollController(context, largeTitle),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: .only(
              top:
                  MediaQuery.of(context).padding.top +
                  kToolbarHeight +
                  ShellScope.appBarTopOf(context),
            ),
          ),
        ),
        if (largeTitle != null)
          ContentSliverPadding(sliver: LargeTitleSliver(title: largeTitle)),

        ...?slivers,
        for (final child in children ?? const <Widget>[])
          SliverToBoxAdapter(child: child),
      ],
    );
  }
}
