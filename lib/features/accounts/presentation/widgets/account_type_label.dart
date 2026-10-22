import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

String accountTypeLabel(AppLocalizations l10n, AccountType type) =>
    switch (type) {
      AccountType.debit => l10n.accountTypeDebit,
      AccountType.cash => l10n.accountTypeCash,
      AccountType.savings => l10n.accountTypeSavings,
      AccountType.credit => l10n.accountTypeCredit,
    };
