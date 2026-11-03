part of 'profile_edit_cubit.dart';

/// Имена совпадают с `ValidationFailure.field` репозитория.
enum ProfileField { name, email, currentPassword, newPassword }

@freezed
abstract class ProfileEditState with _$ProfileEditState {
  const factory ProfileEditState({
    @Default('') String name,
    @Default('') String email,
    @Default(Currency.rub) Currency currency,

    /// Валюта до правки: менять её на сервере, только если выбрали другую.
    @Default(Currency.rub) Currency initialCurrency,

    /// Пустые оба — пароль не меняется.
    @Default('') String currentPassword,
    @Default('') String newPassword,
    @Default(FormStatus.idle) FormStatus status,
    @Default({}) Map<ProfileField, FieldError> fieldErrors,
    Failure? failure,
  }) = _ProfileEditState;
}
