part of 'goal_form_cubit.dart';

/// Имена совпадают с `ValidationFailure.field` репозитория.
enum GoalField { name, target, initialContribution, initialAccountId }

/// Суммы — строки ввода: разбираются только при сохранении.
@freezed
abstract class GoalFormState with _$GoalFormState {
  const factory GoalFormState({
    String? goalId,
    @Default('') String name,
    @Default('') String target,

    /// Только при создании: при правке взнос уже списан со счёта.
    @Default('') String initialContribution,
    String? initialAccountId,
    DateTime? deadline,
    @Default(false) bool isLoading,
    @Default(FormStatus.idle) FormStatus status,

    /// Удаление прошло; [status] при этом не success — тост и переход другие.
    @Default(false) bool deleted,
    @Default({}) Map<GoalField, FieldError> fieldErrors,
    Failure? failure,
  }) = _GoalFormState;

  const GoalFormState._();

  bool get loadFailed => failure != null && status == FormStatus.idle;
}
