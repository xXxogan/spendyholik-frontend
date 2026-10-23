part of 'analytics_cubit.dart';

@freezed
sealed class AnalyticsState with _$AnalyticsState {
  const factory AnalyticsState.loading(PeriodPreset preset) = AnalyticsLoading;

  /// [percents] — доли expenseByCategory в целых процентах, в сумме 100.
  const factory AnalyticsState.loaded(
    AnalyticsReport report,
    PeriodPreset preset,
    List<int> percents,
  ) = AnalyticsLoaded;
  const factory AnalyticsState.empty(PeriodPreset preset) = AnalyticsEmpty;
  const factory AnalyticsState.error(Failure failure, PeriodPreset preset) =
      AnalyticsError;
}
