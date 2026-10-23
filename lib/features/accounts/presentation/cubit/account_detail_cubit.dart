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

part 'account_detail_cubit.freezed.dart';
part 'account_detail_state.dart';

@injectable
class AccountDetailCubit extends Cubit<AccountDetailState>
    with CubitLogging<AccountDetailState> {
  AccountDetailCubit(this._repository, DataChangeBus bus)
    : super(const AccountDetailState.loading()) {
    _changes = bus.changes
        .where(
          (topics) =>
              topics.contains(DataTopic.accounts) ||
              topics.contains(DataTopic.transactions),
        )
        .where((_) => state is AccountDetailLoaded)
        .listen((_) => reload());
  }

  final AccountRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;
  late String _accountId;

  Future<void> load(String accountId) async {
    _accountId = accountId;
    if (state is! AccountDetailLoaded) emit(const AccountDetailState.loading());
    try {
      final account = await _repository.getAccount(accountId);
      final history = await _repository.getBalanceHistory(accountId);
      emit(AccountDetailState.loaded(account, history));
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(AccountDetailState.error(failure));
    }
  }

  Future<void> reload() => load(_accountId);

  Future<void> archive() async {
    try {
      await _repository.archive(_accountId);
      emit(const AccountDetailState.archived());
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(AccountDetailState.error(failure));
    }
  }

  Future<void> unarchive() async {
    try {
      await _repository.unarchive(_accountId);
      await reload();
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(AccountDetailState.error(failure));
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
