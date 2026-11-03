import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/features/user/presentation/pages/user_placeholder.dart';
import 'package:spendyholik/l10n/l10n.dart';

// Экран целиком — T-29.
@RoutePage()
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) => UserPlaceholder(
    title: context.l10n.userRegisterTitle,
    note: context.l10n.userScreenComingSoon,
  );
}
