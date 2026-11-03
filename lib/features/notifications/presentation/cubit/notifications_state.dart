part of 'notifications_cubit.dart';

@freezed
sealed class NotificationsState with _$NotificationsState {
  const factory NotificationsState.loading() = NotificationsLoading;
  const factory NotificationsState.loaded(
    List<NotificationModel> notifications,
  ) = NotificationsLoaded;
  const factory NotificationsState.empty() = NotificationsEmpty;
  const factory NotificationsState.error(Failure failure) = NotificationsError;
}
