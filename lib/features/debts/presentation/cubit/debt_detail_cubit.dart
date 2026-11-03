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

part 'debt_detail_cubit.freezed.dart';
part 'debt_detail_state.dart';

@injectable
class DebtDetailCubit extends Cubit<DebtDetailState>
    with CubitLogging<DebtDetailState> {
  DebtDetailCubit(this._repository, DataChangeBus bus)
    : super(const DebtDetailState.loading()) {
    _changes = bus.changes
        .where((topics) => topics.contains(DataTopic.debts))
        .where((_) => state is DebtDetailLoaded)
        .listen((_) => reload());
  }

  final DebtRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;
  late String _debtId;

  Future<void> load(String debtId) async {
    _debtId = debtId;
    if (state is! DebtDetailLoaded) emit(const DebtDetailState.loading());
    try {
      final debt = await _repository.getDebt(debtId);
      final history = await _repository.getHistory(debtId);
      emit(DebtDetailState.loaded(debt, history));
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(DebtDetailState.error(failure));
    }
  }

  Future<void> reload() => load(_debtId);

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
