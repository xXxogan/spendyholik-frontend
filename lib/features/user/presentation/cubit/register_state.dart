part of 'register_cubit.dart';

enum RegisterField { name, email, password }

@freezed
abstract class RegisterState with _$RegisterState {
  const factory RegisterState({
    @Default('') String name,
    @Default('') String email,
    @Default('') String password,
    @Default(FormStatus.idle) FormStatus status,
    @Default({}) Map<RegisterField, FieldError> fieldErrors,
    Failure? failure,
  }) = _RegisterState;
}
