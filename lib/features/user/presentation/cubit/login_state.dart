part of 'login_cubit.dart';

enum LoginField { email, password }

@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({
    @Default('') String email,
    @Default('') String password,
    @Default(FormStatus.idle) FormStatus status,
    @Default({}) Map<LoginField, FieldError> fieldErrors,
    Failure? failure,
  }) = _LoginState;
}
