import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/api_call.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/session/session_currency.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/debts/data/api/debts_api.dart';
import 'package:spendyholik/features/debts/data/models/debt_dtos.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';
import 'package:spendyholik/features/debts/data/repositories/debt_repository.dart';
import 'package:talker/talker.dart';

@LazySingleton(as: DebtRepository)
class RemoteDebtRepository implements DebtRepository {
  RemoteDebtRepository(
    this._api,
    this._reader,
    this._bus,
    this._session,
    this._talker,
  );

  static const _formFields = {
    'person_name': 'counterparty',
    'amount_minor': 'amount',
  };
  static const _createFields = {
    'person_name': 'counterparty',
    'amount_minor': 'amount',
    'account_id': 'accountId',
  };
  static const _repayFields = {
    'amount_minor': 'amount',
    'account_id': 'accountId',
  };

  static final _day = DateFormat('yyyy-MM-dd');

  final DebtsApi _api;
  final CachedReader _reader;
  final DataChangeBus _bus;
  final SessionCurrency _session;
  final Talker _talker;

  @override
  Future<List<DebtModel>> getDebts() async {
    final dtos = await _reader.read(
      key: cacheKey('debts'),
      fetch: () => _call(_api.list),
      toJson: (list) => [for (final dto in list) dto.toJson()],
      fromJson: (json) => [
        for (final item in json! as List)
          DebtOutDto.fromJson(item as Map<String, dynamic>),
      ],
    );
    final all = dtos.map(_debt).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [...all.where((d) => !d.isClosed), ...all.where((d) => d.isClosed)];
  }

  @override
  Future<DebtModel> getDebt(String id) async => _debt(
    await _reader.read(
      key: cacheKey('debts/$id'),
      fetch: () => _call(() => _api.get(id)),
      toJson: (dto) => dto.toJson(),
      fromJson: (json) => DebtOutDto.fromJson(json! as Map<String, dynamic>),
    ),
  );

  @override
  Future<List<DebtEvent>> getHistory(String id) async {
    final dtos = await _reader.read(
      key: cacheKey('debts/$id/history'),
      fetch: () => _call(() => _api.history(id)),
      toJson: (list) => [for (final dto in list) dto.toJson()],
      fromJson: (json) => [
        for (final item in json! as List)
          DebtEventOutDto.fromJson(item as Map<String, dynamic>),
      ],
    );
    return dtos.map(_event).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<DebtModel> create(DebtDraft draft) async {
    final created = await _call(
      () => _api.create(
        DebtCreateBody(
          personName: draft.counterparty,
          direction: _directionCode(draft.direction),
          amountMinor: draft.amount,
          // Выбора валюты в форме нет: долг — в валюте счёта, без счёта — в базовой.
          currency: (draft.currency ?? _session.value).code,
          dueDate: _date(draft.dueDate),
          note: draft.note ?? '',
          accountId: draft.accountId,
          date: _day.format(draft.openedOn ?? DateTime.now()),
        ),
      ),
      _createFields,
    );
    _bus.emit({
      DataTopic.debts,
      if (draft.accountId != null) DataTopic.accounts,
    });
    return _debt(created);
  }

  /// Направление при правке не уходит: форма его блокирует, а в PATCH поля нет.
  @override
  Future<DebtModel> update(String id, DebtDraft draft) async {
    final updated = await _call(
      () => _api.update(
        id,
        DebtPatchBody(
          personName: draft.counterparty,
          amountMinor: draft.amount,
          dueDate: _date(draft.dueDate),
          note: draft.note ?? '',
        ),
      ),
      _formFields,
    );
    _bus.emit({DataTopic.debts});
    return _debt(updated);
  }

  @override
  Future<void> repay(String id, int amount, String accountId) async {
    await _call(
      () => _api.repay(
        id,
        RepayBody(
          accountId: accountId,
          amountMinor: amount,
          date: _day.format(DateTime.now()),
        ),
      ),
      _repayFields,
    );
    // Шина сразу после записи: перечитывание долга здесь могло упасть уже после
    // списания — пользователь увидел бы ошибку, а повтор погасил бы дважды.
    _bus.emit({DataTopic.debts, DataTopic.accounts});
  }

  DebtModel _debt(DebtOutDto dto) => DebtModel(
    id: dto.id,
    currency: _currency(dto.amount.currency),
    counterparty: dto.personName,
    direction: dto.direction == 'owed_to_me'
        ? DebtDirection.owedToMe
        : DebtDirection.iOwe,
    total: dto.amount.minor,
    remaining: dto.remaining.minor,
    dueDate: switch (dto.dueDate) {
      final date? => DateTime.parse(date),
      null => null,
    },
    note: dto.note.isEmpty ? null : dto.note,
    // Сервер даты не прислал — долг уходит в конец списка, а не прыгает наверх.
    createdAt: switch (dto.createdAt) {
      final at? => DateTime.parse(at),
      null => DateTime.fromMillisecondsSinceEpoch(0),
    },
  );

  DebtEvent _event(DebtEventOutDto dto) => DebtEvent(
    id: dto.id,
    kind: dto.kind == 'repayment'
        ? DebtEventKind.repayment
        : DebtEventKind.opened,
    amount: dto.amount.minor,
    date: DateTime.parse(dto.date),
    account: switch (dto.account) {
      final ref? => AccountRef(
        id: ref.id,
        name: ref.name,
        color: EntityColor.values.asNameMap()[ref.color] ?? EntityColor.gray,
      ),
      null => null,
    },
  );

  static String _directionCode(DebtDirection direction) => switch (direction) {
    .iOwe => 'i_owe',
    .owedToMe => 'owed_to_me',
  };

  Currency _currency(String code) {
    final currency = Currency.fromCode(code);
    if (currency != null) return currency;
    _talker.warning('Unknown debt currency $code, using base');
    return _session.value;
  }

  static String? _date(DateTime? date) =>
      date == null ? null : _day.format(date);

  Future<T> _call<T>(
    Future<T> Function() request, [
    Map<String, String> fields = const {},
  ]) => callApi(request, fields: fields);
}
