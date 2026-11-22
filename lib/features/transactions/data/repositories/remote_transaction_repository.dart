import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:spendyholik/core/config/app_config.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/network/api_call.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/features/transactions/data/api/transactions_api.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/models/transaction_dtos.dart';
import 'package:spendyholik/features/transactions/data/repositories/transaction_mapper.dart';
import 'package:spendyholik/features/transactions/data/repositories/transaction_repository.dart';

@LazySingleton(as: TransactionRepository)
class RemoteTransactionRepository implements TransactionRepository {
  RemoteTransactionRepository(
    this._api,
    this._reader,
    this._bus,
    this._mapper,
  );

  static const _fields = {
    'amount_minor': 'amount',
    'account_id': 'accountId',
    'category_id': 'categoryId',
    'transfer_to_account_id': 'toAccountId',
  };

  /// Категории — из-за счётчиков операций у них.
  static const _changedTopics = {
    DataTopic.transactions,
    DataTopic.accounts,
    DataTopic.budgets,
    DataTopic.categories,
  };

  static final _day = DateFormat('yyyy-MM-dd');
  static final _clock = DateFormat('HH:mm:ss');

  final TransactionsApi _api;
  final CachedReader _reader;
  final DataChangeBus _bus;
  final TransactionMapper _mapper;

  @override
  Future<TransactionPage> getPage(
    TransactionFilter filter, {
    String? cursor,
  }) async {
    final type = filter.type?.name;
    final dateFrom = switch (filter.period) {
      final period? => _day.format(period.start),
      null => null,
    };
    // Период не включает конец, а сервер сравнивает `date_to` включительно.
    final dateTo = switch (filter.period) {
      final period? => _day.format(
        DateTime(period.end.year, period.end.month, period.end.day - 1),
      ),
      null => null,
    };
    final limit = filter.limit ?? AppConfig.transactionsPageSize;

    Future<TransactionPageDto> fetch() => _call(
      () => _api.list(
        type: type,
        accountId: filter.accountId,
        categoryId: filter.categoryId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        cursor: cursor,
        limit: limit,
      ),
    );

    // В кэше только первая страница: следующие зависят от курсора, и офлайн
    // продолжение ленты из старого кэша дало бы дыры.
    final dto = cursor == null
        ? await _reader.read(
            key: cacheKey('transactions', {
              'type': type,
              'account_id': filter.accountId,
              'category_id': filter.categoryId,
              'date_from': dateFrom,
              'date_to': dateTo,
              'limit': limit,
            }),
            fetch: fetch,
            toJson: (dto) => dto.toJson(),
            fromJson: (json) =>
                TransactionPageDto.fromJson(json! as Map<String, dynamic>),
          )
        : await fetch();
    return TransactionPage(
      items: dto.items.map(_mapper.transaction).toList(),
      nextCursor: dto.nextCursor,
    );
  }

  @override
  Future<List<TransactionModel>> getTransactions(TransactionFilter filter) =>
      getPage(filter).then((page) => page.items);

  @override
  Future<TransactionModel> getTransaction(String id) async => _mapper.transaction(
    await _reader.read(
      key: cacheKey('transactions/$id'),
      fetch: () => _call(() => _api.get(id)),
      toJson: (dto) => dto.toJson(),
      fromJson: (json) =>
          TransactionOutDto.fromJson(json! as Map<String, dynamic>),
    ),
  );

  @override
  Future<TransactionModel> create(TransactionDraft draft) async {
    final created = await _call(
      () => _api.create(
        TransactionCreateBody(
          accountId: draft.accountId,
          type: draft.type.name,
          amountMinor: draft.amount,
          date: _day.format(draft.occurredAt),
          categoryId: draft.categoryId,
          time: _clock.format(draft.occurredAt),
          note: draft.note ?? '',
          title: draft.title,
          transferToAccountId: draft.toAccountId,
        ),
      ),
    );
    _bus.emit(_changedTopics);
    return _mapper.transaction(created);
  }

  @override
  Future<TransactionModel> update(String id, TransactionDraft draft) async {
    final updated = await _call(
      () => _api.update(
        id,
        TransactionPatchBody(
          accountId: draft.accountId,
          amountMinor: draft.amount,
          date: _day.format(draft.occurredAt),
          categoryId: draft.categoryId,
          time: draft.hasTime ? _clock.format(draft.occurredAt) : null,
          note: draft.note ?? '',
          title: draft.title,
          transferToAccountId: draft.toAccountId,
        ),
      ),
    );
    _bus.emit(_changedTopics);
    return _mapper.transaction(updated);
  }

  @override
  Future<void> delete(String id) async {
    await _call(() => _api.delete(id));
    _bus.emit(_changedTopics);
  }

  Future<T> _call<T>(Future<T> Function() request) =>
      callApi(request, fields: _fields);
}
