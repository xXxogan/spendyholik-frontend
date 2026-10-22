import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/repositories/repositories.dart';

part 'transactions_cubit.freezed.dart';
part 'transactions_state.dart';

@injectable
class TransactionsCubit extends Cubit<TransactionsState> {
  TransactionsCubit(this._repository, DataChangeBus bus)
    : super(const TransactionsState.loading()) {
    _changes = bus.changes
        .where(
          (topics) =>
              topics.contains(DataTopic.transactions) ||
              topics.contains(DataTopic.accounts) ||
              topics.contains(DataTopic.categories),
        )
        .listen((_) => load(_filter));
  }

  final TransactionRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;
  var _filter = const TransactionFilter();

  /// Скелетон — только пока данных ещё не было: при смене фильтра старый
  /// список остаётся на экране до прихода нового.
  Future<void> load(TransactionFilter filter) async {
    _filter = filter;
    if (state is TransactionsLoading || state is TransactionsError) {
      emit(const TransactionsState.loading());
    }
    try {
      final transactions = await _repository.getTransactions(filter);
      if (filter != _filter) return;
      emit(
        transactions.isEmpty
            ? TransactionsState.empty(filter)
            : TransactionsState.loaded(_groupByDay(transactions), filter),
      );
    } on Failure catch (failure) {
      emit(TransactionsState.error(failure));
    }
  }

  Future<void> setType(TransactionType? type) => load(_filter.withType(type));

  Future<void> applyFilter(TransactionFilter filter) => load(filter);

  static List<TransactionDayGroup> _groupByDay(
    List<TransactionModel> transactions,
  ) {
    final sorted = List.of(transactions)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final groups = <TransactionDayGroup>[];
    for (final transaction in sorted) {
      final at = transaction.occurredAt;
      final day = DateTime(at.year, at.month, at.day);
      if (groups.isNotEmpty && groups.last.day == day) {
        groups.last.items.add(transaction);
      } else {
        groups.add(TransactionDayGroup(day: day, items: [transaction]));
      }
    }
    return groups;
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
