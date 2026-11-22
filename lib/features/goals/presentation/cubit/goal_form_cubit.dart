import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/goals/data/models/models.dart';
import 'package:spendyholik/features/goals/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'goal_form_cubit.freezed.dart';
part 'goal_form_state.dart';

@injectable
class GoalFormCubit extends Cubit<GoalFormState>
    with CubitLogging<GoalFormState> {
  GoalFormCubit(this._repository) : super(const GoalFormState());

  final GoalRepository _repository;

  Future<void> init(String goalId) async {
    emit(GoalFormState(goalId: goalId, isLoading: true));
    try {
      final goal = await _repository.getGoal(goalId);
      emit(
        GoalFormState(
          goalId: goalId,
          name: goal.name,
          target: formatAmountInput(goal.target),
          currency: goal.currency,
          deadline: goal.deadline,
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(GoalFormState(goalId: goalId, failure: failure));
    }
  }

  void nameChanged(String value) =>
      emit(state.copyWith(name: value, fieldErrors: _without(.name)));

  void targetChanged(String value) => emit(
    state.copyWith(
      target: value,
      fieldErrors: _without(.target)..remove(GoalField.initialContribution),
    ),
  );

  void initialContributionChanged(String value) => emit(
    state.copyWith(
      initialContribution: value,
      fieldErrors: _without(.initialContribution),
    ),
  );

  void initialAccountChanged(String? value) => emit(
    state.copyWith(
      initialAccountId: value,
      fieldErrors: _without(.initialAccountId),
    ),
  );

  void deadlineChanged(DateTime? value) =>
      emit(state.copyWith(deadline: value));

  Future<void> save() async {
    final isNew = state.goalId == null;
    final errors = <GoalField, FieldError>{};
    final name = state.name.trim();
    if (name.isEmpty) errors[.name] = .required;
    final target = parseAmountInput(state.target);
    if (target == null) errors[.target] = .invalidAmount;
    final contribution = isNew ? _contribution() : 0;
    if (contribution == null) {
      errors[.initialContribution] = .invalidAmount;
    } else if (target != null && contribution > target) {
      errors[.initialContribution] = .exceedsTarget;
    } else if (contribution > 0 && state.initialAccountId == null) {
      errors[.initialAccountId] = .required;
    }
    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }

    final draft = GoalDraft(
      name: name,
      target: target!,
      initialContribution: contribution!,
      initialAccountId: contribution > 0 ? state.initialAccountId : null,
      deadline: state.deadline,
    );
    emit(state.copyWith(status: .submitting, failure: null));
    try {
      final goalId = state.goalId;
      if (goalId == null) {
        await _repository.create(draft);
      } else {
        await _repository.update(goalId, draft);
      }
      emit(state.copyWith(status: .success));
    } on ValidationFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      final field = GoalField.values.asNameMap()[failure.field];
      emit(
        field == null
            ? state.copyWith(status: .failure, failure: failure)
            : state.copyWith(
                status: .failure,
                fieldErrors: {field: failure.reason},
              ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  Future<void> delete() async {
    emit(state.copyWith(status: .submitting, failure: null));
    try {
      await _repository.delete(state.goalId!);
      emit(state.copyWith(deleted: true));
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  /// Взнос необязателен: пусто или ноль — 0; `parseAmountInput` нулю даёт null.
  int? _contribution() {
    final input = state.initialContribution;
    if (!RegExp('[1-9]').hasMatch(input)) return 0;
    return parseAmountInput(input);
  }

  Map<GoalField, FieldError> _without(GoalField field) =>
      Map.of(state.fieldErrors)..remove(field);
}
