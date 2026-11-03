part of 'goal_top_up_cubit.dart';

/// Имена совпадают с `ValidationFailure.field` репозитория.
enum TopUpField { amount, accountId }

/// Сумма — строка ввода: разбирается только при отправке.
@freezed
abstract class GoalTopUpState with _$GoalTopUpState {
  const factory GoalTopUpState({
    String? goalId,
    @Default('') String amount,
    String? accountId,
    @Default(FormStatus.idle) FormStatus status,
    @Default({}) Map<TopUpField, FieldError> fieldErrors,
    Failure? failure,
  }) = _GoalTopUpState;
}
