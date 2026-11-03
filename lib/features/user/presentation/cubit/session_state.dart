part of 'session_cubit.dart';

@freezed
sealed class SessionState with _$SessionState {
  /// Сессия ещё восстанавливается — Splash и guard'ы ждут.
  const factory SessionState.unknown() = SessionUnknown;
  const factory SessionState.unauthenticated({required bool onboardingSeen}) =
      SessionUnauthenticated;
  const factory SessionState.authenticated(UserModel user) =
      SessionAuthenticated;
}
