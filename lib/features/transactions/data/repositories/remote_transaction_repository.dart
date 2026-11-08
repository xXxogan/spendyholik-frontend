import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:spendyholik/core/config/app_config.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/failure_mapper.dart';
import 'package:spendyholik/core/session/session_currency.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/categories/categories.dart';
import 'package:spendyholik/features/transactions/data/api/transactions_api.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/models/transaction_dtos.dart';
import 'package:spendyholik/features/transactions/data/repositories/transaction_repository.dart';
import 'package:talker/talker.dart';

@LazySingleton(as: TransactionRepository)
class RemoteTransactionRepository implements TransactionRepository {
  RemoteTransactionRepository(
    this._api,
    this._reader,
    this._bus,
    this._session,
    this._talker,
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
  final SessionCurrency _session;
  final Talker _talker;

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
      items: dto.items.map(_transaction).toList(),
      nextCursor: dto.nextCursor,
    );
  }

  @override
  Future<List<TransactionModel>> getTransactions(TransactionFilter filter) =>
      getPage(filter).then((page) => page.items);

  @override
  Future<TransactionModel> getTransaction(String id) async => _transaction(
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
    return _transaction(created);
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
          time: _clock.format(draft.occurredAt),
          note: draft.note ?? '',
          title: draft.title,
          transferToAccountId: draft.toAccountId,
        ),
      ),
    );
    _bus.emit(_changedTopics);
    return _transaction(updated);
  }

  @override
  Future<void> delete(String id) async {
    await _call(() => _api.delete(id));
    _bus.emit(_changedTopics);
  }

  TransactionModel _transaction(TransactionOutDto dto) {
    final day = DateTime.parse(dto.date);
    // Без времени — полдень, чтобы операция не уезжала на соседний день.
    final parts = (dto.time ?? '12:00:00').split(':');
    final note = dto.note;
    return TransactionModel(
      id: dto.id,
      currency: _currency(dto.amount.currency),
      type:
          TransactionType.values.asNameMap()[dto.type] ??
          TransactionType.expense,
      amount: dto.amount.minor,
      title: dto.title,
      category: switch (dto.category) {
        final ref? => CategoryRef(
          id: ref.id,
          name: ref.name ?? '',
          icon: EntityIcon.values.asNameMap()[ref.icon] ?? EntityIcon.other,
          color: EntityColor.values.asNameMap()[ref.color] ?? EntityColor.gray,
        ),
        null => null,
      },
      account: _accountRef(dto.account),
      toAccount: switch (dto.transferToAccount) {
        final ref? => _accountRef(ref),
        null => null,
      },
      occurredAt: DateTime(
        day.year,
        day.month,
        day.day,
        int.tryParse(parts[0]) ?? 12,
        parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
        parts.length > 2 ? int.tryParse(parts[2].split('.').first) ?? 0 : 0,
      ),
      note: note == null || note.isEmpty ? null : note,
    );
  }

  AccountRef _accountRef(AccountRefDto dto) => AccountRef(
    id: dto.id,
    name: dto.name,
    color: EntityColor.values.asNameMap()[dto.color] ?? EntityColor.gray,
  );

  Currency _currency(String code) {
    final currency = Currency.fromCode(code);
    if (currency != null) return currency;
    _talker.warning('Unknown transaction currency $code, using base');
    return _session.value;
  }

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw mapDioException(e, fields: _fields);
    }
  }
}
