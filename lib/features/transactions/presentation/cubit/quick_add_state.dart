part of 'quick_add_cubit.dart';

enum QuickAddField { amount, category, account }

@freezed
abstract class QuickAddState with _$QuickAddState {
  const factory QuickAddState({
    @Default(TransactionType.expense) TransactionType type,
    @Default('') String amount,
    String? categoryId,

    /// Валюта счёта, на который уйдёт операция; null, пока он неизвестен.
    Currency? accountCurrency,

    /// Самые используемые категории верхнего уровня выбранного типа.
    @Default([]) List<CategoryModel> categories,
    @Default(true) bool isLoading,
    @Default(FormStatus.idle) FormStatus status,
    @Default({}) Map<QuickAddField, FieldError> fieldErrors,
    Failure? failure,
  }) = _QuickAddState;
}
