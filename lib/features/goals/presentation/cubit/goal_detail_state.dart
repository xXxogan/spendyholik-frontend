part of 'goal_detail_cubit.dart';

@freezed
sealed class GoalDetailState with _$GoalDetailState {
  const factory GoalDetailState.loading() = GoalDetailLoading;

  /// [forecast] — дата достижения от сервера; null — пополнений нет или
  /// прогноз не загрузился.
  const factory GoalDetailState.loaded(
    GoalModel goal,
    List<GoalContribution> contributions,
    DateTime? forecast,
  ) = GoalDetailLoaded;
  const factory GoalDetailState.deleted() = GoalDetailDeleted;
  const factory GoalDetailState.error(Failure failure) = GoalDetailError;
}
