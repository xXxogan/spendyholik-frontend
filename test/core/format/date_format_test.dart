import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:spendyholik/core/format/date_format.dart';
import 'package:spendyholik/l10n/app_localizations_ru.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  final l10n = AppLocalizationsRu();
  final today = DateTime(2026, 10, 22, 14);

  test('сегодня', () {
    expect(
      formatDayLabel(DateTime(2026, 10, 22, 8), today, l10n, 'ru'),
      'Сегодня',
    );
  });

  test('вчера', () {
    expect(formatDayLabel(DateTime(2026, 10, 21), today, l10n, 'ru'), 'Вчера');
  });

  test('этот год — без года', () {
    expect(
      formatDayLabel(DateTime(2026, 3, 12), today, l10n, 'ru'),
      '12 марта',
    );
  });

  test('другой год — с годом', () {
    expect(
      formatDayLabel(DateTime(2025, 3, 12), today, l10n, 'ru'),
      '12 марта 2025',
    );
  });

  test('вчера через границу года', () {
    expect(
      formatDayLabel(DateTime(2025, 12, 31), DateTime(2026, 1, 1), l10n, 'ru'),
      'Вчера',
    );
  });
}
