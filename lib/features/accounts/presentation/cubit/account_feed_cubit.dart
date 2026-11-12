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

part 'account_feed_cubit.freezed.dart';
part 'account_feed_state.dart';

/// Устроен как `TransactionsCubit`, но без фильтров и без сортировки: время
/// есть только у операций, а сервер упорядочивает ленту по дню и моменту записи.
@injectable
class AccountFeedCubit extends Cubit<AccountFeedState>
    with CubitLogging<AccountFeedState> {
  AccountFeedCubit(this._repository, DataChangeBus bus)
    : super(const AccountFeedState.loading()) {
    _changes = bus.changes
        .where((topics) => topics.any(_topics.contains))
        .listen((_) {
          if (_accountId case final id?) load(id);
        });
  }

  static const _topics = {
    DataTopic.transactions,
    DataTopic.accounts,
    DataTopic.goals,
    DataTopic.debts,
  };

  final AccountFeedRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;
  String? _accountId;
  var _items = <FeedEntry>[];

  /// Растёт с каждым load: страница, запрошенная до перезагрузки, не должна
  /// дописаться к новой первой странице.
  var _generation = 0;

  Future<void> load(String accountId) async {
    _accountId = accountId;
    final generation = ++_generation;
    if (state is AccountFeedLoading || state is AccountFeedError) {
      emit(const AccountFeedState.loading());
    }
    try {
      final page = await _repository.getPage(accountId);
      if (generation != _generation) return;
      _items = page.items;
      emit(
        _items.isEmpty
            ? const AccountFeedState.empty()
            : AccountFeedState.loaded(
                _groupByDay(_items),
                nextCursor: page.nextCursor,
              ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      if (generation != _generation) return;
      emit(AccountFeedState.error(failure));
    }
  }

  /// Ничего не делает, если всё загружено или страница уже идёт. После ошибки
  /// повторяет ту же страницу.
  Future<void> loadMore() async {
    final current = state;
    final accountId = _accountId;
    if (current is! AccountFeedLoaded || current.loadingMore) return;
    final cursor = current.nextCursor;
    if (cursor == null || accountId == null) return;
    final generation = _generation;
    emit(current.copyWith(loadingMore: true, moreFailure: null));
    try {
      final page = await _repository.getPage(accountId, cursor: cursor);
      if (generation != _generation) return;
      final known = {for (final e in _items) e.key};
      // Сервер мог сдвинуть границу страницы после новой записи.
      _items = [..._items, ...page.items.where((e) => !known.contains(e.key))];
      emit(
        AccountFeedState.loaded(
          _groupByDay(_items),
          nextCursor: page.nextCursor,
        ),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      if (generation != _generation) return;
      emit(
        (state as AccountFeedLoaded).copyWith(
          loadingMore: false,
          moreFailure: failure,
        ),
      );
    }
  }

  /// Подгрузка при прокрутке к концу; после ошибки молчит до «Повторить»
  /// ([loadMore]), иначе без сети каждая перестройка списка была бы запросом.
  Future<void> autoLoadMore() async {
    if (state case AccountFeedLoaded(moreFailure: null)) await loadMore();
  }

  static List<FeedDayGroup> _groupByDay(List<FeedEntry> entries) {
    final byDay = <DateTime, List<FeedEntry>>{};
    for (final entry in entries) {
      final at = entry.date;
      byDay
          .putIfAbsent(DateTime(at.year, at.month, at.day), () => [])
          .add(entry);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final day in days) FeedDayGroup(day: day, items: byDay[day]!)];
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
