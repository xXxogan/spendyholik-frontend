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

  static const _forecastWindowMonths = 3;

  final GoalRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;
  late String _goalId;

  /// Месяцев до цели при среднем пополнении за последние 3 месяца.
  static int? forecastMonths(
    GoalModel goal,
    List<GoalContribution> contributions,
    DateTime now,
  ) {
    if (goal.isReached) return 0;
    final since = DateTime(
      now.year,
      now.month - _forecastWindowMonths,
      now.day,
    );
    final recent = contributions
        .where((c) => !c.date.isBefore(since) && !c.date.isAfter(now))
        .fold(0, (sum, c) => sum + c.amount);
    if (recent == 0) return null;
    return (goal.remaining * _forecastWindowMonths / recent).ceil();
  }

  Future<void> load(String goalId) async {
    _goalId = goalId;
    if (state is! GoalDetailLoaded) emit(const GoalDetailState.loading());
    try {
      final goal = await _repository.getGoal(goalId);
      final contributions = await _repository.getContributions(goalId);
      emit(
        GoalDetailState.loaded(
          goal,
          contributions,
          forecastMonths(goal, contributions, DateTime.now()),
        ),
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

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
