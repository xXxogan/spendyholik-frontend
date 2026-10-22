import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/layout/window_size.dart';

class DashboardLayout extends StatelessWidget {
  const DashboardLayout({super.key, required this.primary, required this.secondary});

  final List<Widget> primary;
  final List<Widget> secondary;

  static const _gap = 20.0;

  @override
  Widget build(BuildContext context) {
    if (context.windowSize != WindowSize.expanded) {
      return _column([...primary, ...secondary]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _column(primary)),
        const SizedBox(width: _gap),
        Expanded(child: _column(secondary)),
      ],
    );
  }

  Widget _column(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: _gap),
        children[i],
      ],
    ],
  );
}
