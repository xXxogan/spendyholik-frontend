part of 'goal_detail_cubit.dart';

@freezed
sealed class GoalDetailState with _$GoalDetailState {
  const factory GoalDetailState.loading() = GoalDetailLoading;

  /// [forecastMonths]: null — пополнений за 3 месяца нет, прогноза нет.
  const factory GoalDetailState.loaded(
    GoalModel goal,
    List<GoalContribution> contributions,
    int? forecastMonths,
  ) = GoalDetailLoaded;
  const factory GoalDetailState.deleted() = GoalDetailDeleted;
  const factory GoalDetailState.error(Failure failure) = GoalDetailError;
}
