import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

String currencyLabel(AppLocalizations l10n, Currency currency) =>
    switch (currency) {
      Currency.rub => l10n.currencyRub,
      Currency.usd => l10n.currencyUsd,
      Currency.eur => l10n.currencyEur,
      Currency.kzt => l10n.currencyKzt,
      Currency.byn => l10n.currencyByn,
      Currency.gel => l10n.currencyGel,
      Currency.uah => l10n.currencyUah,
      Currency.cny => l10n.currencyCny,
    };
