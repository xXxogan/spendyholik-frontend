import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'total_balance_cubit.freezed.dart';
part 'total_balance_state.dart';

@injectable
class TotalBalanceCubit extends Cubit<TotalBalanceState>
    with CubitLogging<TotalBalanceState> {
  TotalBalanceCubit(this._repository, DataChangeBus bus)
    : super(const TotalBalanceState.loading()) {
    _changes = bus.changes
        .where(
          (topics) =>
              topics.contains(DataTopic.accounts) ||
              topics.contains(DataTopic.transactions),
        )
        .listen((_) => load());
  }

  final AccountRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;

  Future<void> load() async {
    if (state is! TotalBalanceLoaded) emit(const TotalBalanceState.loading());
    try {
      emit(TotalBalanceState.loaded(await _repository.getTotalBalance()));
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(TotalBalanceState.error(failure));
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
