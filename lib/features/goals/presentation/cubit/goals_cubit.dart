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

part 'goals_cubit.freezed.dart';
part 'goals_state.dart';

@injectable
class GoalsCubit extends Cubit<GoalsState> with CubitLogging<GoalsState> {
  GoalsCubit(this._repository, DataChangeBus bus)
    : super(const GoalsState.loading()) {
    _changes = bus.changes
        .where((topics) => topics.contains(DataTopic.goals))
        .listen((_) => load());
  }

  final GoalRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;

  GoalModel? get nearest => switch (state) {
    GoalsLoaded(:final goals) => nearestOf(goals),
    _ => null,
  };

  /// Без достигнутых: с ближайшим дедлайном, а если дедлайнов нет —
  /// с наибольшим прогрессом.
  static GoalModel? nearestOf(List<GoalModel> goals) {
    final open = goals.where((goal) => !goal.isReached).toList();
    final withDeadline = open.where((goal) => goal.deadline != null).toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
    if (withDeadline.isNotEmpty) return withDeadline.first;
    open.sort((a, b) => b.progress.compareTo(a.progress));
    return open.firstOrNull;
  }

  Future<void> load() async {
    if (state is! GoalsLoaded) emit(const GoalsState.loading());
    try {
      final goals = await _repository.getGoals();
      emit(goals.isEmpty ? const GoalsState.empty() : GoalsState.loaded(goals));
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(GoalsState.error(failure));
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
