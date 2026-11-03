import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/features/budgets/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'budgets_cubit.freezed.dart';
part 'budgets_state.dart';

@injectable
class BudgetsCubit extends Cubit<BudgetsState> with CubitLogging<BudgetsState> {
  BudgetsCubit(this._repository, DataChangeBus bus)
    : super(const BudgetsState.loading()) {
    _changes = bus.changes
        .where((topics) => topics.contains(DataTopic.budgets))
        .listen((_) => load());
  }

  final BudgetRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;

  Future<void> load() async {
    if (state is! BudgetsLoaded) emit(const BudgetsState.loading());
    try {
      final budgets = await _repository.getBudgets();
      emit(
        budgets.isEmpty
            ? const BudgetsState.empty()
            : BudgetsState.loaded(budgets),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(BudgetsState.error(failure));
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
