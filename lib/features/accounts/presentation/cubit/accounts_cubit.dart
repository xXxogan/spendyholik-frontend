import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/repositories.dart';

part 'accounts_cubit.freezed.dart';
part 'accounts_state.dart';

enum AccountsFilter { all, active, archived }

@injectable
class AccountsCubit extends Cubit<AccountsState> {
  AccountsCubit(this._repository, DataChangeBus bus)
    : super(const AccountsState.loading()) {
    _changes = bus.changes
        .where((topics) => topics.contains(DataTopic.accounts))
        .listen((_) => load());
  }

  final AccountRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;

  List<AccountModel>? _accounts;
  AccountsFilter _filter = AccountsFilter.all;

  Future<void> load() async {
    if (_accounts == null) emit(const AccountsState.loading());
    try {
      final accounts = await _repository.getAccounts();
      _accounts = [
        ...accounts.where((account) => !account.isArchived),
        ...accounts.where((account) => account.isArchived),
      ];
      _emitVisible();
    } on Failure catch (failure) {
      emit(AccountsState.error(failure));
    }
  }

  void setFilter(AccountsFilter filter) {
    _filter = filter;
    if (_accounts != null) _emitVisible();
  }

  void _emitVisible() {
    final visible = _accounts!.where(switch (_filter) {
      AccountsFilter.all => (_) => true,
      AccountsFilter.active => (account) => !account.isArchived,
      AccountsFilter.archived => (account) => account.isArchived,
    }).toList();

    emit(
      visible.isEmpty
          ? AccountsState.empty(_filter)
          : AccountsState.loaded(visible, _filter),
    );
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
