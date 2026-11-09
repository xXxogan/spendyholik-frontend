import 'dart:async';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/failure_mapper.dart';
import 'package:spendyholik/features/analytics/data/api/analytics_api.dart';
import 'package:spendyholik/features/analytics/data/models/analytics_dtos.dart';
import 'package:spendyholik/features/analytics/data/models/models.dart';
import 'package:spendyholik/features/analytics/data/repositories/analytics_repository.dart';
import 'package:spendyholik/features/categories/categories.dart';

@LazySingleton(as: AnalyticsRepository)
class RemoteAnalyticsRepository implements AnalyticsRepository {
  RemoteAnalyticsRepository(this._api, this._reader);

  static const _months = 6;
  static const _years = 3;

  static final _day = DateFormat('yyyy-MM-dd');

  final AnalyticsApi _api;
  final CachedReader _reader;

  @override
  Future<AnalyticsReport> getReport(
    PeriodPreset preset, {
    DateTime? anchor,
  }) async {
    final period = DatePeriod.current(preset, anchor ?? DateTime.now());
    final (granularity, trendStart) = _trendWindow(preset, period);
    final (current, previous, categories, trend) = await _all(
      period,
      granularity,
      trendStart,
    );

    final prevExpense = previous.expense.minor;
    return AnalyticsReport(
      period: period,
      income: current.income.minor,
      expense: current.expense.minor,
      expenseChange: prevExpense == 0
          ? null
          : (current.expense.minor - prevExpense) / prevExpense,
      expenseByCategory: [
        for (final dto in categories)
          CategoryShare(
            category: _category(dto),
            amount: dto.amount.minor,
            share: dto.ratio,
          ),
      ],
      // Сервер отдаёт все отрезки окна, в том числе пустые.
      trend: [
        for (final dto in trend)
          PeriodTotals(
            start: DateTime.parse(dto.start),
            income: dto.income.minor,
            expense: dto.expense.minor,
          ),
      ],
    );
  }

  /// `.wait` оборачивает ошибки в `ParallelWaitError`, а наверх нужен сам `Failure`.
  Future<
    (
      SummaryOutDto,
      SummaryOutDto,
      List<CategorySpendingOutDto>,
      List<TrendPointOutDto>,
    )
  >
  _all(DatePeriod period, String granularity, DateTime trendStart) async {
    try {
      return await (
        _summary(period),
        _summary(period.previous()),
        _byCategory(period),
        _trend(granularity, trendStart, period),
      ).wait;
    } on ParallelWaitError<
      dynamic,
      (AsyncError?, AsyncError?, AsyncError?, AsyncError?)
    > catch (e) {
      final (a, b, c, d) = e.errors;
      throw (a ?? b ?? c ?? d)!.error;
    }
  }

  /// Неделя — 7 дней отчёта, месяц — последние 6 месяцев, год — последние 3 года;
  /// последний отрезок содержит период отчёта.
  (String, DateTime) _trendWindow(PeriodPreset preset, DatePeriod period) {
    final s = period.start;
    return switch (preset) {
      PeriodPreset.week => ('day', s),
      PeriodPreset.year => ('year', DateTime(s.year - (_years - 1))),
      PeriodPreset.month || PeriodPreset.custom => (
        'month',
        DateTime(s.year, s.month - (_months - 1)),
      ),
    };
  }

  Map<String, Object?> _query(DateTime from, DateTime endExclusive) => {
    'date_from': _day.format(from),
    'date_to': _day.format(
      DateTime(endExclusive.year, endExclusive.month, endExclusive.day - 1),
    ),
  };

  Future<SummaryOutDto> _summary(DatePeriod period) {
    final query = _query(period.start, period.end);
    return _reader.read(
      key: cacheKey('analytics/summary', query),
      fetch: () => _call(
        () => _api.summary(
          query['date_from']! as String,
          query['date_to']! as String,
        ),
      ),
      toJson: (dto) => dto.toJson(),
      fromJson: (json) => SummaryOutDto.fromJson(json! as Map<String, dynamic>),
    );
  }

  Future<List<CategorySpendingOutDto>> _byCategory(DatePeriod period) {
    final query = _query(period.start, period.end);
    return _reader.read(
      key: cacheKey('analytics/by-category', query),
      fetch: () => _call(
        () => _api.byCategory(
          query['date_from']! as String,
          query['date_to']! as String,
        ),
      ),
      toJson: (list) => [for (final dto in list) dto.toJson()],
      fromJson: (json) => [
        for (final item in json! as List)
          CategorySpendingOutDto.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  Future<List<TrendPointOutDto>> _trend(
    String granularity,
    DateTime from,
    DatePeriod period,
  ) {
    final query = _query(from, period.end);
    return _reader.read(
      key: cacheKey('analytics/trend', {'granularity': granularity, ...query}),
      fetch: () => _call(
        () => _api.trend(
          granularity,
          query['date_from']! as String,
          query['date_to']! as String,
        ),
      ),
      toJson: (list) => [for (final dto in list) dto.toJson()],
      fromJson: (json) => [
        for (final item in json! as List)
          TrendPointOutDto.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  CategoryRef _category(CategorySpendingOutDto dto) {
    final ref = dto.category;
    return CategoryRef(
      id: ref?.id ?? dto.categoryId,
      name: ref?.name ?? dto.categoryName,
      icon: EntityIcon.values.asNameMap()[ref?.icon] ?? EntityIcon.other,
      color: EntityColor.values.asNameMap()[ref?.color] ?? EntityColor.gray,
    );
  }

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
