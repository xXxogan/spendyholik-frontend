import 'package:material_ui/material_ui.dart';

class ContentCard extends StatelessWidget {
  const ContentCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: .zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: .circular(24)),
      child: Padding(padding: const .all(20), child: child),
    );
  }
}
