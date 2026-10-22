import 'package:intl/intl.dart';
import 'package:spendyholik/core/models/currency.dart';

const _minusSign = '−';
const _nbsp = ' ';

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
