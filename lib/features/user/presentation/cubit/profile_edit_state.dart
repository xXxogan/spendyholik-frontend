part of 'profile_edit_cubit.dart';

/// Имена совпадают с `ValidationFailure.field` репозитория.
enum ProfileField { name, email, currentPassword }

@freezed
abstract class ProfileEditState with _$ProfileEditState {
  const ProfileEditState._();

  const factory ProfileEditState({
    @Default('') String name,
    @Default('') String email,

    /// Email до правки: при смене сервер спрашивает текущий пароль.
    @Default('') String initialEmail,
    @Default(Currency.rub) Currency currency,

    /// Валюта до правки: менять её на сервере, только если выбрали другую.
    @Default(Currency.rub) Currency initialCurrency,

    /// Текущий пароль — сервер спрашивает его при смене email (T-53).
    @Default('') String currentPassword,
    @Default(FormStatus.idle) FormStatus status,
    @Default({}) Map<ProfileField, FieldError> fieldErrors,
    Failure? failure,
  }) = _ProfileEditState;

  /// Изменён ли email — тогда в форме поле текущего пароля, и оно обязательно.
  bool get emailChanged =>
      email.trim().toLowerCase() != initialEmail.trim().toLowerCase();
}
