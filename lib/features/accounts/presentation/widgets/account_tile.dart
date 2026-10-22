import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/presentation/widgets/account_subtitle.dart';

class AccountTile extends StatelessWidget {
  const AccountTile({
    super.key,
    required this.account,
    required this.currency,
    this.onTap,
  });

  final AccountModel account;
  final Currency currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final locale = Localizations.localeOf(context).toString();
    final accentColor = AppColors.entity(account.color, brightness);

    return Card(
      margin: .zero,
      elevation: 0,
      color: theme.colorScheme.surface,
      clipBehavior: .antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const .symmetric(horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: accentColor.withValues(
                  alpha: account.isArchived ? 0.08 : 0.16,
                ),
                foregroundColor: accentColor,
                child: Icon(_icons[account.type]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: .center,
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      account.name,
                      style: theme.textTheme.titleMedium,
                      overflow: .ellipsis,
                    ),
                    Text(
                      accountSubtitle(context, account, currency),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: .ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatMoney(account.balance, currency, locale),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: account.balance < 0
                      ? AppColors.negative(brightness)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _icons = {
    AccountType.debit: Icons.credit_card,
    AccountType.cash: Icons.payments_outlined,
    AccountType.savings: Icons.savings_outlined,
    AccountType.credit: Icons.credit_score,
  };
}
