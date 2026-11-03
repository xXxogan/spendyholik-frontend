import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/goals/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'goal_top_up_cubit.freezed.dart';
part 'goal_top_up_state.dart';

@injectable
class GoalTopUpCubit extends Cubit<GoalTopUpState>
    with CubitLogging<GoalTopUpState> {
  GoalTopUpCubit(this._repository) : super(const GoalTopUpState());

  final GoalRepository _repository;

  void init(String goalId) => emit(GoalTopUpState(goalId: goalId));

  void amountChanged(String value) =>
      emit(state.copyWith(amount: value, fieldErrors: _without(.amount)));

  void accountChanged(String? value) =>
      emit(state.copyWith(accountId: value, fieldErrors: _without(.accountId)));

  Future<void> submit() async {
    final errors = <TopUpField, FieldError>{};
    final amount = parseAmountInput(state.amount);
    if (amount == null) errors[.amount] = .invalidAmount;
    final accountId = state.accountId;
    if (accountId == null) errors[.accountId] = .required;
    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }

    emit(state.copyWith(status: .submitting, failure: null));
    try {
      await _repository.contribute(state.goalId!, amount!, accountId!);
      emit(state.copyWith(status: .success));
    } on ValidationFailure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(
        state.copyWith(
          status: .failure,
          fieldErrors: {
            TopUpField.values.byName(failure.field): failure.reason,
          },
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(state.copyWith(status: .failure, failure: failure));
    }
  }

  Map<TopUpField, FieldError> _without(TopUpField field) =>
      Map.of(state.fieldErrors)..remove(field);
}
