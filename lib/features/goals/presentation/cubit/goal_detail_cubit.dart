import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/goals/data/models/models.dart';
import 'package:spendyholik/features/goals/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'goal_detail_cubit.freezed.dart';
part 'goal_detail_state.dart';

@injectable
class GoalDetailCubit extends Cubit<GoalDetailState>
    with CubitLogging<GoalDetailState> {
  GoalDetailCubit(this._repository, DataChangeBus bus)
    : super(const GoalDetailState.loading()) {
    _changes = bus.changes
        .where((topics) => topics.contains(DataTopic.goals))
        .where((_) => state is GoalDetailLoaded)
        .listen((_) => reload());
  }

  final GoalRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;
  late String _goalId;

  Future<void> load(String goalId) async {
    _goalId = goalId;
    if (state is! GoalDetailLoaded) emit(const GoalDetailState.loading());
    try {
      final goal = await _repository.getGoal(goalId);
      final contributions = await _repository.getContributions(goalId);
      emit(
        GoalDetailState.loaded(goal, contributions, await _forecast(goalId)),
      );
    } on Failure catch (failure, stackTrace) {
      // Открытая цель пропала — её удалили (в том числе формой поверх деталей).
      if (failure is NotFoundFailure && state is GoalDetailLoaded) {
        emit(const GoalDetailState.deleted());
        return;
      }
      getIt<Talker>().handle(failure, stackTrace);
      emit(GoalDetailState.error(failure));
    }
  }

  Future<void> reload() => load(_goalId);

  /// Прогноз — дополнение к экрану: без него цель и история всё равно видны.
  Future<DateTime?> _forecast(String goalId) async {
    try {
      return await _repository.getForecast(goalId);
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace, 'Goal forecast failed');
      return null;
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
