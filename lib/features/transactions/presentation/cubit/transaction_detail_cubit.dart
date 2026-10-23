import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'transaction_detail_cubit.freezed.dart';
part 'transaction_detail_state.dart';

@injectable
class TransactionDetailCubit extends Cubit<TransactionDetailState>
    with CubitLogging<TransactionDetailState> {
  TransactionDetailCubit(this._repository, DataChangeBus bus)
    : super(const TransactionDetailState.loading()) {
    // Своё удаление тоже приходит по шине, и раньше, чем его await: без
    // _deleting перезагрузка получит NotFound уже после deleted.
    _changes = bus.changes
        .where(
          (topics) =>
              topics.contains(DataTopic.transactions) ||
              topics.contains(DataTopic.accounts) ||
              topics.contains(DataTopic.categories),
        )
        .where((_) => state is TransactionDetailLoaded && !_deleting)
        .listen((_) => reload());
  }

  final TransactionRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;
  late String _transactionId;
  var _deleting = false;

  Future<void> load(String transactionId) async {
    _transactionId = transactionId;
    if (state is! TransactionDetailLoaded) {
      emit(const TransactionDetailState.loading());
    }
    try {
      emit(
        TransactionDetailState.loaded(
          await _repository.getTransaction(transactionId),
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(TransactionDetailState.error(failure));
    }
  }

  Future<void> reload() => load(_transactionId);

  Future<void> delete() async {
    _deleting = true;
    try {
      await _repository.delete(_transactionId);
      emit(const TransactionDetailState.deleted());
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      _deleting = false;
      emit(TransactionDetailState.error(failure));
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
