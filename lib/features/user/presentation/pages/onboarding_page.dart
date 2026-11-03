import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/features/user/presentation/pages/user_placeholder.dart';
import 'package:spendyholik/l10n/l10n.dart';

// Экран целиком — T-28.
@RoutePage()
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) => UserPlaceholder(
    title: context.l10n.userOnboardingTitle,
    note: context.l10n.userScreenComingSoon,
  );
}
