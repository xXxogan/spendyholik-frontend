part of 'transaction_form_cubit.dart';

/// Имена совпадают с полями `TransactionDraft` — по ним сервер называет поле в
/// `ValidationFailure`.
enum TransactionField { amount, categoryId, accountId, toAccountId }

/// Сумма — строка ввода: разбирается только при сохранении.
@freezed
abstract class TransactionFormState with _$TransactionFormState {
  const factory TransactionFormState({
    String? transactionId,
    @Default(TransactionType.expense) TransactionType type,
    @Default('') String amount,
    @Default('') String title,
    String? categoryId,
    String? accountId,
    String? toAccountId,

    /// null только до init.
    DateTime? occurredAt,
    @Default('') String note,
    @Default(false) bool isLoading,
    @Default(FormStatus.idle) FormStatus status,
    @Default({}) Map<TransactionField, FieldError> fieldErrors,
    Failure? failure,
  }) = _TransactionFormState;

  const TransactionFormState._();

  bool get loadFailed => failure != null && status == FormStatus.idle;
}
