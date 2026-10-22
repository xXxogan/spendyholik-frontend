import 'package:intl/intl.dart';
import 'package:spendyholik/core/models/currency.dart';

const _minusSign = '\u2212';
const _nbsp = '\u00a0';

/// [minor] — сумма в минорных единицах (копейки, центы).
String formatMoney(int minor, Currency currency, String locale, {bool signed = false}) {
  final hasFraction = minor % 100 != 0;
  final number = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: hasFraction ? 2 : 0,
  ).format(minor.abs() / 100);
  final sign = minor < 0 ? _minusSign : (signed && minor > 0 ? '+' : '');

  return locale.startsWith('ru')
      ? '$sign$number$_nbsp${currency.symbol}'
      : '$sign${currency.symbol}$number';
}

/// Для подписей осей графиков: без копеек, «120 тыс. ₽».
String formatMoneyCompact(int minor, Currency currency, String locale) {
  final number = NumberFormat.compact(locale: locale).format(minor.abs() / 100);
  final sign = minor < 0 ? _minusSign : '';

  return locale.startsWith('ru')
      ? '$sign$number$_nbsp${currency.symbol}'
      : '$sign${currency.symbol}$number';
}

/// Принимает «1 240,5» и «1240.50»; возвращает минорные единицы. Ноль, пусто и мусор — null.
int? parseAmountInput(String input) {
  final cleaned = input.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(cleaned)) return null;

  final parts = cleaned.split('.');
  final fraction = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
  final minor = int.parse(parts[0]) * 100 + int.parse(fraction);
  return minor > 0 ? minor : null;
}
