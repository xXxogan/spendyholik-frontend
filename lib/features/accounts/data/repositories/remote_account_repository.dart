import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/failure_mapper.dart';
import 'package:spendyholik/core/session/session_currency.dart';
import 'package:spendyholik/features/accounts/data/api/accounts_api.dart';
import 'package:spendyholik/features/accounts/data/models/account_dtos.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/account_repository.dart';
import 'package:talker/talker.dart';

@LazySingleton(as: AccountRepository)
class RemoteAccountRepository implements AccountRepository {
  RemoteAccountRepository(
    this._api,
    this._reader,
    this._bus,
    this._session,
    this._talker,
  );

  static const _fields = {
    'name': 'name',
    'initial_balance_minor': 'balance',
    'balance_minor': 'balance',
    'last4': 'cardLast4',
    'credit_limit_minor': 'creditLimit',
    'interest_rate': 'interestRate',
  };

  final AccountsApi _api;
  final CachedReader _reader;
  final DataChangeBus _bus;
  final SessionCurrency _session;
  final Talker _talker;

  @override
  Future<List<AccountModel>> getAccounts() async {
    final dtos = await _reader.read(
      key: cacheKey('accounts', {'include_archived': true}),
      fetch: () => _call(() => _api.list(true)),
      toJson: (list) => [for (final dto in list) dto.toJson()],
      fromJson: (json) => [
        for (final item in json! as List)
          AccountOutDto.fromJson(item as Map<String, dynamic>),
      ],
    );
    return dtos.map(_account).toList();
  }

  @override
  Future<AccountModel> getAccount(String id) async => _account(
    await _reader.read(
      key: cacheKey('accounts/$id'),
      fetch: () => _call(() => _api.get(id)),
      toJson: (dto) => dto.toJson(),
      fromJson: (json) => AccountOutDto.fromJson(json! as Map<String, dynamic>),
    ),
  );

  @override
  Future<TotalBalance> getTotalBalance() async {
    final dashboard = await _reader.read(
      key: cacheKey('dashboard'),
      fetch: () => _call(_api.dashboard),
      toJson: (dto) => dto.toJson(),
      fromJson: (json) =>
          DashboardOutDto.fromJson(json! as Map<String, dynamic>),
    );
    return TotalBalance(
      total: dashboard.totalBalance.minor,
      monthDelta: dashboard.netThisMonth.minor,
    );
  }

  @override
  Future<List<BalancePoint>> getBalanceHistory(
    String id, {
    int weeks = 6,
  }) async {
    final points = await _reader.read(
      key: cacheKey('accounts/$id/balance-history', {'weeks': weeks}),
      fetch: () => _call(() => _api.history(id, weeks)),
      toJson: (list) => [for (final point in list) point.toJson()],
      fromJson: (json) => [
        for (final item in json! as List)
          BalancePointOutDto.fromJson(item as Map<String, dynamic>),
      ],
    );
    return [
      for (final point in points)
        BalancePoint(at: point.at, balance: point.balance.minor),
    ];
  }

  @override
  Future<AccountModel> create(AccountDraft draft) async {
    final created = await _call(
      () => _api.create(
        AccountCreateBody(
          name: draft.name,
          type: draft.type.name,
          // Выбора валюты в форме нет: новый счёт — в базовой (решение 2026-11-07).
          currency: _session.value.code,
          initialBalanceMinor: draft.balance,
          color: draft.color.name,
          last4: draft.cardLast4,
          creditLimitMinor: draft.creditLimit,
          interestRate: _rate(draft.interestRate),
        ),
      ),
    );
    _bus.emit({DataTopic.accounts});
    return _account(created);
  }

  @override
  Future<AccountModel> update(String id, AccountDraft draft) async {
    final updated = await _call(
      () => _api.update(
        id,
        AccountPatchBody(
          name: draft.name,
          type: draft.type.name,
          balanceMinor: draft.balance,
          color: draft.color.name,
          last4: draft.cardLast4,
          creditLimitMinor: draft.creditLimit,
          interestRate: _rate(draft.interestRate),
        ),
      ),
    );
    // Имя счёта видно в операциях, истории целей и долгов, шаблонах.
    _bus.emit({
      DataTopic.accounts,
      DataTopic.transactions,
      DataTopic.goals,
      DataTopic.debts,
      DataTopic.recurring,
    });
    return _account(updated);
  }

  @override
  Future<void> archive(String id) async {
    await _call(() => _api.archive(id));
    _bus.emit({DataTopic.accounts});
  }

  @override
  Future<void> unarchive(String id) async {
    await _call(() => _api.unarchive(id));
    _bus.emit({DataTopic.accounts});
  }

  AccountModel _account(AccountOutDto dto) {
    final type = AccountType.values.asNameMap()[dto.type] ?? AccountType.debit;
    final rate = double.tryParse(dto.interestRate) ?? 0;
    return AccountModel(
      id: dto.id,
      currency: _currency(dto.currency),
      name: dto.name,
      type: type,
      balance: dto.balance.minor,
      color: EntityColor.values.asNameMap()[dto.color] ?? EntityColor.gray,
      isArchived: dto.isArchived,
      cardLast4: dto.last4,
      // Сервер отдаёт «0» у любого счёта; ставка есть только у вклада.
      interestRate: type == AccountType.savings ? rate : null,
      creditLimit: dto.creditLimit?.minor,
    );
  }

  Currency _currency(String code) {
    final currency = Currency.fromCode(code);
    if (currency != null) return currency;
    _talker.warning('Unknown account currency $code, using base');
    return _session.value;
  }

  /// Десятичная строка для API: 7.5 → «7.5», 0 → «0».
  static String _rate(double? rate) {
    final value = rate ?? 0;
    return value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw mapDioException(e, fields: _fields);
    }
  }
}
