part of 'notification_preferences_cubit.dart';

@freezed
sealed class NotificationPreferencesState with _$NotificationPreferencesState {
  const factory NotificationPreferencesState.loading() =
      NotificationPreferencesLoading;

  /// [failure] — последнее несохранённое переключение, уже откатанное: для тоста.
  const factory NotificationPreferencesState.loaded(
    NotificationPreferences preferences, {
    Failure? failure,
  }) = NotificationPreferencesLoaded;
  const factory NotificationPreferencesState.error(Failure failure) =
      NotificationPreferencesError;
}
