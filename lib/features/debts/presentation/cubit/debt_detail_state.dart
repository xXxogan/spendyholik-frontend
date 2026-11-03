part of 'debt_detail_cubit.dart';

@freezed
sealed class DebtDetailState with _$DebtDetailState {
  const factory DebtDetailState.loading() = DebtDetailLoading;
  const factory DebtDetailState.loaded(
    DebtModel debt,
    List<DebtEvent> history,
  ) = DebtDetailLoaded;
  const factory DebtDetailState.error(Failure failure) = DebtDetailError;
}
