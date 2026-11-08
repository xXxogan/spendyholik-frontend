part of 'recurring_form_cubit.dart';

/// Имена совпадают с `ValidationFailure.field` репозитория.
enum RecurringField { title, amount, categoryId, accountId }

/// Сумма — строка ввода: разбирается только при сохранении.
@freezed
abstract class RecurringFormState with _$RecurringFormState {
  const factory RecurringFormState({
    String? recurringId,
    @Default('') String title,
    @Default(TransactionType.expense) TransactionType type,
    @Default('') String amount,
    String? categoryId,
    String? accountId,

    /// Валюта выбранного счёта; null — счёт не выбран или валюта ещё не известна.
    Currency? accountCurrency,
    @Default(RecurrenceFrequency.monthly) RecurrenceFrequency frequency,

    /// Первое выполнение; null, пока форма не инициализирована.
    DateTime? anchor,
    @Default(false) bool isLoading,
    @Default(FormStatus.idle) FormStatus status,
    @Default({}) Map<RecurringField, FieldError> fieldErrors,
    Failure? failure,
  }) = _RecurringFormState;

  const RecurringFormState._();

  bool get loadFailed => failure != null && status == FormStatus.idle;

  DateTime? nextExecution(DateTime now) {
    final anchor = this.anchor;
    return anchor == null ? null : frequency.nextAfter(anchor, now);
  }
}
