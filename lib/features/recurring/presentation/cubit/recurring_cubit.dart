import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/recurring/data/models/models.dart';
import 'package:spendyholik/features/recurring/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'recurring_cubit.freezed.dart';
part 'recurring_state.dart';

@injectable
class RecurringCubit extends Cubit<RecurringState>
    with CubitLogging<RecurringState> {
  RecurringCubit(this._repository, DataChangeBus bus)
    : super(const RecurringState.loading()) {
    _changes = bus.changes
        .where((topics) => topics.contains(DataTopic.recurring))
        .listen((_) => load());
  }

  final RecurringRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;

  Future<void> load() async {
    if (state is! RecurringLoaded) emit(const RecurringState.loading());
    try {
      final templates = await _repository.getAll();
      emit(
        templates.isEmpty
            ? const RecurringState.empty()
            : RecurringState.loaded(templates),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(RecurringState.error(failure));
    }
  }

  Future<void> togglePause(String id) async {
    final templates = switch (state) {
      RecurringLoaded(:final templates) => templates,
      _ => const <RecurringModel>[],
    };
    final template = templates.where((t) => t.id == id).firstOrNull;
    if (template == null) return;
    try {
      await _repository.setPaused(id, !template.isPaused);
      await load();
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(RecurringState.error(failure));
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
