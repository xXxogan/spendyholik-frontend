import 'package:intl/intl.dart';
import 'package:spendyholik/core/models/currency.dart';

const _minusSign = '\u2212';
const _nbsp = '\u00a0';

/// [minor] — сумма в минорных единицах (копейки, центы).
String formatMoney(
  int minor,
  Currency currency,
  String locale, {
  bool signed = false,
}) {
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
  final match = _amount.firstMatch(cleaned);
  if (match == null) return null;

  final whole = match.group(1)!;
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  final minor =
      int.parse(whole.isEmpty ? '0' : whole) * 100 + int.parse(fraction);
  return minor > 0 ? minor : null;
}

// Целая часть — до 12 цифр без ведущих нулей: длиннее int переполнялся
// (на Web — терял точность в double) и сумма сохранялась молча неверной.
final _amount = RegExp(r'^0*(\d{0,12})(?:\.(\d{0,2}))?$');

/// Для балансов счёта: как [parseAmountInput], но ноль и минус допустимы.
int? parseSignedAmountInput(String input) {
  final trimmed = input.trim();
  final negative = trimmed.startsWith('-') || trimmed.startsWith(_minusSign);
  final body = negative ? trimmed.substring(1) : trimmed;
  final minor = parseAmountInput(body) ?? _zero(body);
  if (minor == null) return null;
  return negative ? -minor : minor;
}

int? _zero(String input) =>
    RegExp(r'^0+([.,]0{0,2})?$').hasMatch(input.trim()) ? 0 : null;

/// Сумма для поля ввода: без разрядов, копейки через точку, только если есть.
String formatAmountInput(int minor) {
  final sign = minor < 0 ? '-' : '';
  final whole = minor.abs() ~/ 100;
  final fraction = minor.abs() % 100;
  return fraction == 0
      ? '$sign$whole'
      : '$sign$whole.${fraction.toString().padLeft(2, '0')}';
}
