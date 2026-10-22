import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

class AccountTile extends StatelessWidget {
  const AccountTile({super.key, required this.account, required this.currency});

  final AccountModel account;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final locale = Localizations.localeOf(context).toString();
    final accentColor = AppColors.entity(account.color, brightness);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: accentColor.withValues(alpha: account.isArchived ? 0.08 : 0.16),
              foregroundColor: accentColor,
              child: Icon(_icons[account.type]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                  Text(
                    _subtitle(context, locale),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatMoney(account.balance, currency, locale),
              style: theme.textTheme.titleMedium?.copyWith(
                color: account.balance < 0 ? AppColors.negative(brightness) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(BuildContext context, String locale) {
    final l10n = context.l10n;
    final type = switch (account.type) {
      AccountType.debit => l10n.accountTypeDebit,
      AccountType.cash => l10n.accountTypeCash,
      AccountType.savings => l10n.accountTypeSavings,
      AccountType.credit => l10n.accountTypeCredit,
    };
    final details = [
      if (account.isArchived) l10n.accountArchived,
      if (account.cardLast4 case final last4?) l10n.accountCardMask(last4),
      if (account.interestRate case final rate?)
        l10n.accountInterest(NumberFormat.decimalPattern(locale).format(rate)),
      if (account.creditLimit case final limit?)
        l10n.accountCreditLimit(formatMoney(limit, currency, locale)),
    ];

    return [type, ...details].join(' · ');
  }

  static const _icons = {
    AccountType.debit: Icons.credit_card,
    AccountType.cash: Icons.payments_outlined,
    AccountType.savings: Icons.savings_outlined,
    AccountType.credit: Icons.credit_score,
  };
}
