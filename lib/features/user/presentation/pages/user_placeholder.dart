import 'package:material_ui/material_ui.dart';

/// Экран, у которого пока есть только заголовок.
class UserPlaceholder extends StatelessWidget {
  const UserPlaceholder({super.key, required this.title, required this.note});

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const .all(24),
          child: Column(
            mainAxisSize: .min,
            spacing: 8,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              Text(
                note,
                textAlign: .center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
