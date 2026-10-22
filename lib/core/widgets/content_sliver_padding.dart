import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/layout/window_size.dart';

/// Горизонтальные отступы по ширине окна и ограничение контента
/// [Breakpoints.contentMaxWidth] по центру.
class ContentSliverPadding extends StatelessWidget {
  const ContentSliverPadding({super.key, required this.sliver});

  final Widget sliver;

  static const _edges = {
    WindowSize.compact: 16.0,
    WindowSize.medium: 24.0,
    WindowSize.expanded: 32.0,
  };

  @override
  Widget build(BuildContext context) {
    final edge = _edges[context.windowSize]!;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final horizontal = max(
          edge,
          (constraints.crossAxisExtent - Breakpoints.contentMaxWidth) / 2,
        );
        return SliverPadding(
          padding: .symmetric(horizontal: horizontal),
          sliver: sliver,
        );
      },
    );
  }
}
