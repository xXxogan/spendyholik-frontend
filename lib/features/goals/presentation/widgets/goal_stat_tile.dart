import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';

class GoalStatTile extends StatelessWidget {
  const GoalStatTile({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ContentCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(value, style: theme.textTheme.titleLarge),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
