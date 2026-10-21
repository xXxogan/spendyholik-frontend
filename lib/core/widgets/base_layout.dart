import 'package:material_ui/material_ui.dart';

class BaseLayout extends StatelessWidget {
  const BaseLayout({super.key, required this.children});

  final List<Widget> children;

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

        for (final child in children) SliverToBoxAdapter(child: child),
      ],
    );
  }
}
