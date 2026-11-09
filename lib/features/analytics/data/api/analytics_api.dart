import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:spendyholik/features/analytics/data/models/analytics_dtos.dart';

part 'analytics_api.g.dart';

/// Даты — yyyy-MM-dd, `date_to` включительно.
@lazySingleton
@RestApi()
abstract class AnalyticsApi {
  @factoryMethod
  factory AnalyticsApi(Dio dio) = _AnalyticsApi;

  @GET('analytics/summary/')
  Future<SummaryOutDto> summary(
    @Query('date_from') String dateFrom,
    @Query('date_to') String dateTo,
  );

  @GET('analytics/by-category/')
  Future<List<CategorySpendingOutDto>> byCategory(
    @Query('date_from') String dateFrom,
    @Query('date_to') String dateTo,
  );

  /// [granularity]: day | month | year.
  @GET('analytics/trend/')
  Future<List<TrendPointOutDto>> trend(
    @Query('granularity') String granularity,
    @Query('date_from') String dateFrom,
    @Query('date_to') String dateTo,
  );
}
