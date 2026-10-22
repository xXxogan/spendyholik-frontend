import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/core/models/date_period.dart';

void main() {
  group('DatePeriod.current', () {
    test('week: начинается с понедельника', () {
      // 2026-10-22 — четверг
      final p = DatePeriod.current(
        PeriodPreset.week,
        DateTime(2026, 10, 22, 15, 30),
      );
      expect(p.start, DateTime(2026, 10, 19));
      expect(p.end, DateTime(2026, 10, 26));
    });

    test('week: в понедельник и воскресенье', () {
      final mon = DatePeriod.current(PeriodPreset.week, DateTime(2026, 10, 19));
      final sun = DatePeriod.current(
        PeriodPreset.week,
        DateTime(2026, 10, 25, 23, 59),
      );
      expect(mon.start, DateTime(2026, 10, 19));
      expect(sun.start, DateTime(2026, 10, 19));
      expect(sun.end, DateTime(2026, 10, 26));
    });

    test('week: на границе месяца', () {
      // 2026-11-01 — воскресенье
      final p = DatePeriod.current(PeriodPreset.week, DateTime(2026, 11, 1));
      expect(p.start, DateTime(2026, 10, 26));
      expect(p.end, DateTime(2026, 11, 2));
    });

    test('month: граница месяца и декабрь', () {
      final p = DatePeriod.current(
        PeriodPreset.month,
        DateTime(2026, 10, 31, 23),
      );
      expect(p.start, DateTime(2026, 10));
      expect(p.end, DateTime(2026, 11));
      final dec = DatePeriod.current(PeriodPreset.month, DateTime(2026, 12, 5));
      expect(dec.end, DateTime(2027));
    });

    test('year', () {
      final p = DatePeriod.current(PeriodPreset.year, DateTime(2026, 6, 15));
      expect(p.start, DateTime(2026));
      expect(p.end, DateTime(2027));
    });
  });

  group('previous', () {
    test('week', () {
      final p = DatePeriod.current(
        PeriodPreset.week,
        DateTime(2026, 10, 22),
      ).previous();
      expect(p.start, DateTime(2026, 10, 12));
      expect(p.end, DateTime(2026, 10, 19));
    });

    test('month: январь → декабрь прошлого года', () {
      final p = DatePeriod.current(
        PeriodPreset.month,
        DateTime(2026, 1, 10),
      ).previous();
      expect(p.start, DateTime(2025, 12));
      expect(p.end, DateTime(2026));
    });

    test('month: март → февраль', () {
      final p = DatePeriod.current(
        PeriodPreset.month,
        DateTime(2026, 3, 10),
      ).previous();
      expect(p.start, DateTime(2026, 2));
      expect(p.end, DateTime(2026, 3));
    });

    test('year', () {
      final p = DatePeriod.current(
        PeriodPreset.year,
        DateTime(2026, 6, 1),
      ).previous();
      expect(p.start, DateTime(2025));
      expect(p.end, DateTime(2026));
    });
  });

  test('contains: start включительно, end не включительно', () {
    final p = DatePeriod(start: DateTime(2026, 10), end: DateTime(2026, 11));
    expect(p.contains(DateTime(2026, 10)), isTrue);
    expect(p.contains(DateTime(2026, 10, 31, 23, 59, 59)), isTrue);
    expect(p.contains(DateTime(2026, 11)), isFalse);
    expect(p.contains(DateTime(2026, 9, 30, 23, 59)), isFalse);
  });
}
