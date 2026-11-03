part of 'recurring_cubit.dart';

@freezed
sealed class RecurringState with _$RecurringState {
  const factory RecurringState.loading() = RecurringLoading;
  const factory RecurringState.loaded(List<RecurringModel> templates) =
      RecurringLoaded;
  const factory RecurringState.empty() = RecurringEmpty;
  const factory RecurringState.error(Failure failure) = RecurringError;
}
