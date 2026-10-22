import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/content_card.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

class AccountBalanceCard extends StatelessWidget {
  const AccountBalanceCard({
    super.key,
    required this.account,
    required this.currency,
  });

  final AccountModel account;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    return ContentCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            context.l10n.accountDetailCurrentBalance,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatMoney(account.balance, currency, locale),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: .w700,
              color: account.balance < 0
                  ? AppColors.negative(theme.brightness)
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            accountSubtitle(context, account, currency),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
