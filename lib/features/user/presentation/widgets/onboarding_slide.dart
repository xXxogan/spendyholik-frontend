import 'package:material_ui/material_ui.dart';

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: .center,
      spacing: 16,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: .circular(36),
          ),
          child: Icon(icon, size: 56, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: .center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: .w700),
        ),
        Text(
          text,
          textAlign: .center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
