import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

String accountSubtitle(
  BuildContext context,
  AccountModel account,
  Currency currency,
) {
  final locale = Localizations.localeOf(context).toString();
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
