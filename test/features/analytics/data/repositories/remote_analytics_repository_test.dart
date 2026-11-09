import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/analytics/data/api/analytics_api.dart';
import 'package:spendyholik/features/analytics/data/models/analytics_dtos.dart';
import 'package:spendyholik/features/analytics/data/repositories/remote_analytics_repository.dart';
import 'package:talker/talker.dart';

import '../../../../helpers/dio_errors.dart';

class MockAnalyticsApi extends Mock implements AnalyticsApi {}

class MockApiCache extends Mock implements ApiCache {}

Map<String, dynamic> money(int minor) => {
  'minor': minor,
  'currency': 'RUB',
  'formatted': '',
};

/// Форма `SummaryOut` из схемы API.
SummaryOutDto summary({int income = 0, int expense = 0}) =>
    SummaryOutDto.fromJson({
      'income': money(income),
      'expense': money(expense),
      'net': money(income - expense),
      'excluded_currencies': <String>[],
    });

/// Форма `TrendPointOut`.
TrendPointOutDto point(String start, {int income = 0, int expense = 0}) =>
    TrendPointOutDto.fromJson({
      'start': start,
      'income': money(income),
      'expense': money(expense),
    });

void main() {
  late MockAnalyticsApi api;
  late MockApiCache cache;
  late RemoteAnalyticsRepository repository;

  // Среда 2026-10-14: неделя 12–18 окт., прошлая — 5–11 окт.
  final anchor = DateTime(2026, 10, 14);

  void stub({
    SummaryOutDto? current,
    SummaryOutDto? previous,
    List<CategorySpendingOutDto> categories = const [],
    List<TrendPointOutDto> trend = const [],
  }) {
    when(() => api.summary(any(), any())).thenAnswer(
      (i) async => i.positionalArguments[1] == '2026-10-18'
          ? current ?? summary()
          : previous ?? summary(),
    );
    when(() => api.byCategory(any(), any()))
        .thenAnswer((_) async => categories);
    when(() => api.trend(any(), any(), any())).thenAnswer((_) async => trend);
  }

  setUp(() {
    api = MockAnalyticsApi();
    cache = MockApiCache();
    when(() => cache.read(any())).thenAnswer((_) async => null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    repository = RemoteAnalyticsRepository(
      api,
      CachedReader(cache, NetworkStatus(), Talker()),
    );
  });

  group('запросы', () {
    test('неделя: trend day за 7 дней, прошлый период — previous()', () async {
      stub();

      await repository.getReport(.week, anchor: anchor);

      verify(() => api.summary('2026-10-12', '2026-10-18')).called(1);
      verify(() => api.summary('2026-10-05', '2026-10-11')).called(1);
      verify(() => api.byCategory('2026-10-12', '2026-10-18')).called(1);
      verify(() => api.trend('day', '2026-10-12', '2026-10-18')).called(1);
    });

    test('месяц: trend month за 6 месяцев', () async {
      stub();

      await repository.getReport(.month, anchor: anchor);

      verify(() => api.summary('2026-10-01', '2026-10-31')).called(1);
      verify(() => api.summary('2026-09-01', '2026-09-30')).called(1);
      verify(() => api.trend('month', '2026-05-01', '2026-10-31')).called(1);
    });

    test('год: trend year за 3 года', () async {
      stub();

      await repository.getReport(.year, anchor: anchor);

      verify(() => api.summary('2026-01-01', '2026-12-31')).called(1);
      verify(() => api.summary('2025-01-01', '2025-12-31')).called(1);
      verify(() => api.trend('year', '2024-01-01', '2026-12-31')).called(1);
    });
  });

  group('сборка отчёта', () {
    test('суммы, период, trend и доли категорий', () async {
      stub(
        current: summary(income: 90000, expense: 50000),
        categories: [
          CategorySpendingOutDto.fromJson({
            'category': {
              'id': 'food',
              'name': 'Продукты',
              'icon': 'cart',
              'color': 'green',
            },
            'category_id': 'food',
            'category_name': 'Продукты',
            'amount': money(30000),
            'ratio': 0.6,
          }),
          CategorySpendingOutDto.fromJson({
            'category': null,
            'category_id': 'x',
            'category_name': 'Старая',
            'amount': money(20000),
            'ratio': 0.4,
          }),
        ],
        trend: [point('2026-10-12', income: 1, expense: 2)],
      );

      final r = await repository.getReport(.week, anchor: anchor);

      expect(r.period, DatePeriod.current(.week, anchor));
      expect(r.income, 90000);
      expect(r.expense, 50000);
      expect(r.expenseByCategory, hasLength(2));
      final food = r.expenseByCategory.first;
      expect(food.category.id, 'food');
      expect(food.category.icon, EntityIcon.cart);
      expect(food.category.color, EntityColor.green);
      expect(food.amount, 30000);
      expect(food.share, 0.6);
      final fallback = r.expenseByCategory.last.category;
      expect(fallback.name, 'Старая');
      expect(fallback.icon, EntityIcon.other);
      expect(fallback.color, EntityColor.gray);
      expect(r.trend.single.start, DateTime(2026, 10, 12));
      expect(r.trend.single.income, 1);
      expect(r.trend.single.expense, 2);
    });

    test('expenseChange: (exp − prev) / prev', () async {
      stub(current: summary(expense: 150), previous: summary(expense: 100));

      final r = await repository.getReport(.week, anchor: anchor);

      expect(r.expenseChange, closeTo(0.5, 1e-9));
    });

    test('expenseChange: в прошлом расходов нет — null', () async {
      stub(current: summary(expense: 150));

      final r = await repository.getReport(.week, anchor: anchor);

      expect(r.expenseChange, isNull);
    });
  });

  group('ошибки', () {
    test('одна из четырёх упала — Failure', () async {
      stub();
      when(() => api.trend(any(), any(), any())).thenThrow(apiError(500, 'x'));

      await expectLater(
        repository.getReport(.week, anchor: anchor),
        throwsA(isA<Failure>()),
      );
    });
  });
}
