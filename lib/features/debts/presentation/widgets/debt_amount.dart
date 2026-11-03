import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';

/// Остаток со знаком и цветом: «я должен» — «−» и красный, «мне должны» —
/// «+» и зелёный; закрытый — сумма долга без знака и цвета.
(String, Color?) debtAmount(
  DebtModel debt,
  Currency currency,
  String locale,
  Brightness brightness,
) {
  if (debt.isClosed) return (formatMoney(debt.total, currency, locale), null);
  return switch (debt.direction) {
    DebtDirection.iOwe => (
      formatMoney(-debt.remaining, currency, locale),
      AppColors.negative(brightness),
    ),
    DebtDirection.owedToMe => (
      formatMoney(debt.remaining, currency, locale, signed: true),
      AppColors.positive(brightness),
    ),
  };
}
