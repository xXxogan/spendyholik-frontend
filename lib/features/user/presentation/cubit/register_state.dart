part of 'register_cubit.dart';

/// Имена совпадают с `ValidationFailure.field` репозитория.
enum RegisterField { name, email, password, consent }

@freezed
abstract class RegisterState with _$RegisterState {
  const factory RegisterState({
    @Default('') String name,
    @Default('') String email,
    @Default('') String password,

    /// Согласие на обработку ПДн — не отмечено по умолчанию (152-ФЗ, ст. 9).
    @Default(false) bool consent,
    @Default(FormStatus.idle) FormStatus status,
    @Default({}) Map<RegisterField, FieldError> fieldErrors,
    Failure? failure,
  }) = _RegisterState;
}
