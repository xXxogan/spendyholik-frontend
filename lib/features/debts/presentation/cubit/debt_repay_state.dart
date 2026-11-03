part of 'debt_repay_cubit.dart';

/// Имена совпадают с `ValidationFailure.field` репозитория.
enum RepayField { amount, accountId }

/// Сумма — строка ввода: разбирается только при отправке.
@freezed
abstract class DebtRepayState with _$DebtRepayState {
  const factory DebtRepayState({
    String? debtId,
    @Default(0) int remaining,
    @Default('') String amount,
    String? accountId,
    @Default(FormStatus.idle) FormStatus status,
    @Default({}) Map<RepayField, FieldError> fieldErrors,
    Failure? failure,
  }) = _DebtRepayState;
}
