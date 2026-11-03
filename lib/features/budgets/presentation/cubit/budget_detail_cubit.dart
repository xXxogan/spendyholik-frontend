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

part 'budget_detail_cubit.freezed.dart';
part 'budget_detail_state.dart';

@injectable
class BudgetDetailCubit extends Cubit<BudgetDetailState>
    with CubitLogging<BudgetDetailState> {
  BudgetDetailCubit(this._repository, DataChangeBus bus)
    : super(const BudgetDetailState.loading()) {
    _changes = bus.changes
        .where((topics) => topics.contains(DataTopic.budgets))
        .where((_) => state is BudgetDetailLoaded)
        .listen((_) => reload());
  }

  final BudgetRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;
  late String _budgetId;

  Future<void> load(String budgetId) async {
    _budgetId = budgetId;
    if (state is! BudgetDetailLoaded) emit(const BudgetDetailState.loading());
    try {
      emit(BudgetDetailState.loaded(await _repository.getBudget(budgetId)));
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(BudgetDetailState.error(failure));
    }
  }

  Future<void> reload() => load(_budgetId);

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
