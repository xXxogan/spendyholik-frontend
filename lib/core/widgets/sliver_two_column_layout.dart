import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/layout/window_size.dart';

/// Как [TwoColumnLayout], но колонки — slivers: длинный список в колонке
/// строится лениво, а не целиком внутри Row.
class SliverTwoColumnLayout extends StatefulWidget {
  const SliverTwoColumnLayout({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final List<Widget> primary;
  final List<Widget> secondary;

  @override
  State<SliverTwoColumnLayout> createState() => _SliverTwoColumnLayoutState();
}

class _SliverTwoColumnLayoutState extends State<SliverTwoColumnLayout> {
  static const _gap = 20.0;

  // Те же GlobalKey, что в TwoColumnLayout: смена ширины через порог
  // переносит блоки между родителями, не пересоздавая их Cubit.
  final _primaryKeys = <GlobalKey>[];
  final _secondaryKeys = <GlobalKey>[];

  List<Widget> _keyed(List<Widget> slivers, List<GlobalKey> keys) {
    while (keys.length < slivers.length) {
      keys.add(GlobalKey());
    }
    return [
      for (var i = 0; i < slivers.length; i++)
        KeyedSubtree(key: keys[i], child: slivers[i]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final primary = _keyed(widget.primary, _primaryKeys);
    final secondary = _keyed(widget.secondary, _secondaryKeys);

    if (context.windowSize != WindowSize.expanded) {
      return _column([...primary, ...secondary]);
    }

    return SliverCrossAxisGroup(
      slivers: [
        SliverCrossAxisExpanded(flex: 1, sliver: _column(primary)),
        const SliverConstrainedCrossAxis(
          maxExtent: _gap,
          sliver: SliverToBoxAdapter(),
        ),
        SliverCrossAxisExpanded(flex: 1, sliver: _column(secondary)),
      ],
    );
  }

  Widget _column(List<Widget> slivers) => SliverMainAxisGroup(
    slivers: [
      for (var i = 0; i < slivers.length; i++) ...[
        if (i > 0) const SliverToBoxAdapter(child: SizedBox(height: _gap)),
        slivers[i],
      ],
    ],
  );
}
