part of 'budget_form_cubit.dart';

/// Имена совпадают с `ValidationFailure.field` репозитория.
enum BudgetField { categoryId, limit, period }

/// Лимит — строка ввода: разбирается только при сохранении.
@freezed
abstract class BudgetFormState with _$BudgetFormState {
  const factory BudgetFormState({
    String? budgetId,
    String? categoryId,
    @Default('') String limit,
    @Default(BudgetPeriod.monthly) BudgetPeriod period,
    DateTime? onceStart,

    /// Не включительно, как `DatePeriod.end`.
    DateTime? onceEnd,
    @Default(false) bool isLoading,
    @Default(FormStatus.idle) FormStatus status,

    /// Удаление прошло; [status] при этом не success — тост и переход другие.
    @Default(false) bool deleted,
    @Default({}) Map<BudgetField, FieldError> fieldErrors,
    Failure? failure,
  }) = _BudgetFormState;

  const BudgetFormState._();

  bool get loadFailed => failure != null && status == FormStatus.idle;
}
