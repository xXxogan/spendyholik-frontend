import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/l10n/l10n.dart';

class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: context.l10n.appTitlePrefix,
            style: theme.textTheme.titleLarge,
          ),
          TextSpan(
            text: context.l10n.appTitleSuffix,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
