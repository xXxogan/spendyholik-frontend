import 'package:material_ui/material_ui.dart';

class BaseLayout extends StatelessWidget {
  const BaseLayout({super.key, required List<Widget> this.children}) : slivers = null;

  const BaseLayout.slivers({super.key, required List<Widget> this.slivers}) : children = null;

  final List<Widget>? children;
  final List<Widget>? slivers;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: .only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight,
            ),
          ),
        ),

        ...?slivers,
        for (final child in children ?? const <Widget>[]) SliverToBoxAdapter(child: child),
      ],
    );
  }
}
