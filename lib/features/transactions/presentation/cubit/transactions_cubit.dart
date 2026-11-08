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

part 'transactions_cubit.freezed.dart';
part 'transactions_state.dart';

@injectable
class TransactionsCubit extends Cubit<TransactionsState>
    with CubitLogging<TransactionsState> {
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

  /// Всё загруженное по текущему фильтру: группы пересобираются из него
  /// целиком, поэтому день на стыке страниц не рвётся.
  var _items = <TransactionModel>[];

  /// Растёт с каждым load: страница, запрошенная до перезагрузки (шина при
  /// том же фильтре), не должна дописаться к новой первой странице.
  var _generation = 0;

  /// Скелетон — только пока данных ещё не было: при смене фильтра старый
  /// список остаётся на экране до прихода нового.
  Future<void> load(TransactionFilter filter) async {
    _filter = filter;
    final generation = ++_generation;
    if (state is TransactionsLoading || state is TransactionsError) {
      emit(const TransactionsState.loading());
    }
    try {
      final page = await _repository.getPage(filter);
      if (generation != _generation) return;
      _items = page.items;
      emit(
        _items.isEmpty
            ? TransactionsState.empty(filter)
            : TransactionsState.loaded(
                _groupByDay(_items),
                filter,
                nextCursor: page.nextCursor,
              ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(TransactionsState.error(failure));
    }
  }

  /// Следующая страница; ничего не делает, если всё загружено или страница
  /// уже идёт. После ошибки повторяет ту же страницу.
  Future<void> loadMore() async {
    final current = state;
    if (current is! TransactionsLoaded || current.loadingMore) return;
    final cursor = current.nextCursor;
    if (cursor == null) return;
    final filter = _filter;
    final generation = _generation;
    emit(current.copyWith(loadingMore: true, moreFailure: null));
    try {
      final page = await _repository.getPage(filter, cursor: cursor);
      // Пока страница шла, сменился фильтр или пришла шина — она уже не нужна.
      if (generation != _generation) return;
      final known = {for (final t in _items) t.id};
      // Сервер мог сдвинуть границу страницы после новой операции.
      _items = [..._items, ...page.items.where((t) => !known.contains(t.id))];
      emit(
        TransactionsState.loaded(
          _groupByDay(_items),
          filter,
          nextCursor: page.nextCursor,
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      if (generation != _generation) return;
      emit(
        (state as TransactionsLoaded).copyWith(
          loadingMore: false,
          moreFailure: failure,
        ),
      );
    }
  }

  /// Подгрузка из ленивого списка при прокрутке к концу. После ошибки молчит
  /// до «Повторить» ([loadMore]): строки у конца списка перестраиваются часто,
  /// и без сети каждая перестройка была бы новым запросом.
  Future<void> autoLoadMore() async {
    if (state case TransactionsLoaded(moreFailure: null)) await loadMore();
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
