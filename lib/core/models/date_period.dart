enum PeriodPreset { week, month, year, custom }

class DatePeriod {
  const DatePeriod({required this.start, required this.end});

  /// Для [PeriodPreset.custom] границы задаёт вызывающий, поэтому `current` его не принимает.
  factory DatePeriod.current(PeriodPreset preset, DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    return switch (preset) {
      PeriodPreset.week => () {
        final monday = DateTime(day.year, day.month, day.day - (day.weekday - DateTime.monday));
        return DatePeriod(start: monday, end: DateTime(monday.year, monday.month, monday.day + 7));
      }(),
      PeriodPreset.month => DatePeriod(
        start: DateTime(day.year, day.month),
        end: DateTime(day.year, day.month + 1),
      ),
      PeriodPreset.year => DatePeriod(start: DateTime(day.year), end: DateTime(day.year + 1)),
      PeriodPreset.custom => throw ArgumentError.value(preset, 'preset', 'custom has no current'),
    };
  }

  /// Начало дня, включительно.
  final DateTime start;

  /// Не включительно.
  final DateTime end;

  /// Предыдущий период той же длины в календарных единицах: месяц — месяц, год — год,
  /// всё остальное — сдвиг на длину в днях.
  DatePeriod previous() {
    if (start.day == 1 && end.day == 1) {
      final months = (end.year - start.year) * 12 + end.month - start.month;
      return DatePeriod(
        start: DateTime(start.year, start.month - months),
        end: start,
      );
    }
    final days = DateTime.utc(end.year, end.month, end.day)
        .difference(DateTime.utc(start.year, start.month, start.day))
        .inDays;
    return DatePeriod(
      start: DateTime(start.year, start.month, start.day - days),
      end: start,
    );
  }

  bool contains(DateTime moment) => !moment.isBefore(start) && moment.isBefore(end);
}
