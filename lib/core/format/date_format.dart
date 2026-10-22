import 'package:intl/intl.dart';
import 'package:spendyholik/l10n/l10n.dart';

String formatDayLabel(DateTime day, DateTime today, AppLocalizations l10n, String locale) {
  final date = DateTime(day.year, day.month, day.day);
  final now = DateTime(today.year, today.month, today.day);
  if (date == now) return l10n.commonToday;
  if (date == DateTime(now.year, now.month, now.day - 1)) return l10n.commonYesterday;

  final pattern = date.year == now.year ? 'd MMMM' : 'd MMMM y';
  return DateFormat(pattern, locale).format(date);
}
