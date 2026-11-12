part of 'account_feed_cubit.dart';

@freezed
sealed class AccountFeedState with _$AccountFeedState {
  const factory AccountFeedState.loading() = AccountFeedLoading;

  /// Дни по убыванию, внутри дня — порядок сервера. [nextCursor] null —
  /// загружено всё; [loadingMore] — строка-скелетон внизу; [moreFailure] —
  /// внизу «Повторить», загруженное остаётся.
  const factory AccountFeedState.loaded(
    List<FeedDayGroup> groups, {
    String? nextCursor,
    @Default(false) bool loadingMore,
    Failure? moreFailure,
  }) = AccountFeedLoaded;
  const factory AccountFeedState.empty() = AccountFeedEmpty;
  const factory AccountFeedState.error(Failure failure) = AccountFeedError;
}
