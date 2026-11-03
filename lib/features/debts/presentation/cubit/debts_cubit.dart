import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';
import 'package:spendyholik/features/debts/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'debts_cubit.freezed.dart';
part 'debts_state.dart';

@injectable
class DebtsCubit extends Cubit<DebtsState> with CubitLogging<DebtsState> {
  DebtsCubit(this._repository, DataChangeBus bus)
    : super(const DebtsState.loading()) {
    _changes = bus.changes
        .where((topics) => topics.contains(DataTopic.debts))
        .listen((_) => load());
  }

  final DebtRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;

  List<DebtModel>? _debts;
  DebtDirection _direction = .iOwe;

  Future<void> load() async {
    if (_debts == null) emit(const DebtsState.loading());
    try {
      _debts = await _repository.getDebts();
      _emitVisible();
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(DebtsState.error(failure));
    }
  }

  void setDirection(DebtDirection direction) {
    _direction = direction;
    if (_debts != null) _emitVisible();
  }

  void _emitVisible() {
    final visible = _debts!.where((d) => d.direction == _direction).toList();
    emit(
      visible.isEmpty
          ? DebtsState.empty(_direction)
          : DebtsState.loaded(visible, _direction),
    );
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
