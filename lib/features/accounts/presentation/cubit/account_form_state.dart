part of 'account_form_cubit.dart';

enum AccountField { name, balance, cardLast4, interestRate, creditLimit }

/// Числовые поля — строки ввода: разбираются только при сохранении.
@freezed
abstract class AccountFormState with _$AccountFormState {
  const factory AccountFormState({
    String? accountId,
    @Default('') String name,
    @Default(AccountType.debit) AccountType type,
    @Default('') String balance,
    @Default(EntityColor.pink) EntityColor color,
    @Default('') String cardLast4,
    @Default('') String interestRate,
    @Default('') String creditLimit,
    @Default(false) bool isLoading,
    @Default(FormStatus.idle) FormStatus status,
    @Default({}) Map<AccountField, FieldError> fieldErrors,
    Failure? failure,
  }) = _AccountFormState;

  const AccountFormState._();

  /// Счёт для правки не загрузился — вместо формы ошибка и «Повторить».
  bool get loadFailed => failure != null && status == FormStatus.idle;
}
