part of 'debt_form_cubit.dart';

/// Имена совпадают с `ValidationFailure.field` репозитория.
enum DebtField { counterparty, amount }

/// Сумма — строка ввода: разбирается только при сохранении.
@freezed
abstract class DebtFormState with _$DebtFormState {
  const factory DebtFormState({
    String? debtId,
    @Default('') String counterparty,
    @Default(DebtDirection.iOwe) DebtDirection direction,
    @Default('') String amount,
    DateTime? dueDate,
    @Default('') String note,
    @Default(false) bool isLoading,
    @Default(FormStatus.idle) FormStatus status,
    @Default({}) Map<DebtField, FieldError> fieldErrors,
    Failure? failure,
  }) = _DebtFormState;

  const DebtFormState._();

  bool get loadFailed => failure != null && status == FormStatus.idle;
}
