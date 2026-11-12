part of 'forgot_password_cubit.dart';

/// Имена совпадают с `ValidationFailure.field` репозитория.
enum ForgotPasswordField { email, code, newPassword }

enum ForgotPasswordStep { email, code, done }

@freezed
abstract class ForgotPasswordState with _$ForgotPasswordState {
  const factory ForgotPasswordState({
    @Default(ForgotPasswordStep.email) ForgotPasswordStep step,
    @Default('') String email,
    @Default('') String code,
    @Default('') String newPassword,

    /// Секунд до повторной отправки кода; 0 — можно.
    @Default(0) int resendIn,
    @Default(FormStatus.idle) FormStatus status,
    @Default({}) Map<ForgotPasswordField, FieldError> fieldErrors,
    Failure? failure,
  }) = _ForgotPasswordState;
}
