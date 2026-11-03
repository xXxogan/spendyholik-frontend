part of 'goals_cubit.dart';

@freezed
sealed class GoalsState with _$GoalsState {
  const factory GoalsState.loading() = GoalsLoading;
  const factory GoalsState.loaded(List<GoalModel> goals) = GoalsLoaded;
  const factory GoalsState.empty() = GoalsEmpty;
  const factory GoalsState.error(Failure failure) = GoalsError;
}
