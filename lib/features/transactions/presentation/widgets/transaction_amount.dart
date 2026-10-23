import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';

/// Расход — «−» и красный, доход — «+» и зелёный, перевод — без знака и цвета.
(String, Color?) transactionAmount(
  TransactionModel transaction,
  Currency currency,
  String locale,
  Brightness brightness,
) => switch (transaction.type) {
  TransactionType.expense => (
    formatMoney(-transaction.amount, currency, locale),
    AppColors.negative(brightness),
  ),
  TransactionType.income => (
    formatMoney(transaction.amount, currency, locale, signed: true),
    AppColors.positive(brightness),
  ),
  TransactionType.transfer => (
    formatMoney(transaction.amount, currency, locale),
    null,
  ),
};
