part of 'password_change_cubit.dart';

/// Имена совпадают с `ValidationFailure.field` репозитория.
enum PasswordChangeField { code, newPassword }

@freezed
abstract class PasswordChangeState with _$PasswordChangeState {
  const factory PasswordChangeState({
    /// Код отправлен — показываем поле кода и нового пароля.
    @Default(false) bool codeSent,
    @Default('') String code,
    @Default('') String newPassword,

    /// Секунд до повторной отправки кода; 0 — можно.
    @Default(0) int resendIn,
    @Default(FormStatus.idle) FormStatus status,
    @Default({}) Map<PasswordChangeField, FieldError> fieldErrors,
    Failure? failure,
  }) = _PasswordChangeState;
}
