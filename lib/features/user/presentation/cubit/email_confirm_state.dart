part of 'email_confirm_cubit.dart';

@freezed
abstract class EmailConfirmState with _$EmailConfirmState {
  const factory EmailConfirmState({
    @Default('') String email,
    @Default('') String code,

    /// Ошибка у поля кода: неверный, устарел, слишком много попыток.
    FieldError? codeError,

    /// Секунд до «Отправить снова»; 0 — можно отправлять.
    @Default(0) int resendIn,
    @Default(FormStatus.idle) FormStatus status,
    Failure? failure,
  }) = _EmailConfirmState;
}
