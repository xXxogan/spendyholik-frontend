import 'package:intl/intl.dart';
import 'package:spendyholik/l10n/l10n.dart';

String formatDayLabel(
  DateTime day,
  DateTime today,
  AppLocalizations l10n,
  String locale,
) {
  final date = DateTime(day.year, day.month, day.day);
  final now = DateTime(today.year, today.month, today.day);
  if (date == now) return l10n.commonToday;
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  if (date == yesterday) return l10n.commonYesterday;

  final pattern = date.year == now.year ? 'd MMMM' : 'd MMMM y';
  return DateFormat(pattern, locale).format(date);
}

/// «12 мар. 2027 г.» / «Mar 12, 2027».
String formatDate(DateTime date, String locale) =>
    DateFormat.yMMMd(locale).format(date);
