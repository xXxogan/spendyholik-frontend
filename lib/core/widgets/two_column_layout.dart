import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/layout/window_size.dart';

class TwoColumnLayout extends StatefulWidget {
  const TwoColumnLayout({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final List<Widget> primary;
  final List<Widget> secondary;

  @override
  State<TwoColumnLayout> createState() => _TwoColumnLayoutState();
}

class _TwoColumnLayoutState extends State<TwoColumnLayout> {
  static const _gap = 20.0;

  // Row и Column — разные родители: без GlobalKey смена ширины через порог
  // пересоздаёт блоки, и их Cubit заново грузят данные со скелетоном.
  final _primaryKeys = <GlobalKey>[];
  final _secondaryKeys = <GlobalKey>[];

  List<Widget> _keyed(List<Widget> children, List<GlobalKey> keys) {
    while (keys.length < children.length) {
      keys.add(GlobalKey());
    }
    return [
      for (var i = 0; i < children.length; i++)
        KeyedSubtree(key: keys[i], child: children[i]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final primary = _keyed(widget.primary, _primaryKeys);
    final secondary = _keyed(widget.secondary, _secondaryKeys);

    if (context.windowSize != WindowSize.expanded) {
      return _column([...primary, ...secondary]);
    }

    return Row(
      crossAxisAlignment: .start,
      children: [
        Expanded(child: _column(primary)),
        const SizedBox(width: _gap),
        Expanded(child: _column(secondary)),
      ],
    );
  }

  Widget _column(List<Widget> children) => Column(
    crossAxisAlignment: .stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: _gap),
        children[i],
      ],
    ],
  );
}
