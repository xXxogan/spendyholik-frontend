import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/features/recurring/data/models/recurring_model.dart';

void main() {
  group('monthly', () {
    final anchor = DateTime(2026, 1, 31, 10);

    test('31-е → последний день февраля', () {
      expect(
        RecurrenceFrequency.monthly.nextAfter(anchor, anchor),
        DateTime(2026, 2, 28, 10),
      );
    });

    test('после короткого месяца — снова 31-е', () {
      expect(
        RecurrenceFrequency.monthly.nextAfter(
          anchor,
          DateTime(2026, 2, 28, 10),
        ),
        DateTime(2026, 3, 31, 10),
      );
    });

    test('високосный год — 29 февраля', () {
      final leap = DateTime(2028, 1, 31);

      expect(
        RecurrenceFrequency.monthly.nextAfter(leap, leap),
        DateTime(2028, 2, 29),
      );
    });

    test('1-е число: из середины месяца — 1-е следующего', () {
      expect(
        RecurrenceFrequency.monthly.nextAfter(
          DateTime(2026, 1, 1),
          DateTime(2026, 11, 3),
        ),
        DateTime(2026, 12),
      );
    });

    test('якорь ещё впереди — сам якорь', () {
      expect(
        RecurrenceFrequency.monthly.nextAfter(
          DateTime(2026, 12, 15),
          DateTime(2026, 11, 3),
        ),
        DateTime(2026, 12, 15),
      );
    });
  });

  test('weekly — тот же день недели', () {
    expect(
      RecurrenceFrequency.weekly.nextAfter(
        DateTime(2026, 10, 5),
        DateTime(2026, 11, 3),
      ),
      DateTime(2026, 11, 9),
    );
  });

  group('yearly с 29 февраля', () {
    final anchor = DateTime(2024, 2, 29);

    test('невисокосный год — 28 февраля', () {
      expect(
        RecurrenceFrequency.yearly.nextAfter(anchor, anchor),
        DateTime(2025, 2, 28),
      );
    });

    test('високосный — снова 29-е', () {
      expect(
        RecurrenceFrequency.yearly.nextAfter(anchor, DateTime(2027, 3)),
        DateTime(2028, 2, 29),
      );
    });
  });
}
