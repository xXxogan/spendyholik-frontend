import 'package:material_ui/material_ui.dart';

/// Инициалы на акцентном фоне: «Мария Соколова» → «МС».
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();

    return Container(
      width: size,
      height: size,
      alignment: .center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.16),
        borderRadius: .circular(size * 0.32),
      ),
      child: Text(
        initials,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontSize: size * 0.36,
          fontWeight: .w700,
        ),
      ),
    );
  }
}
