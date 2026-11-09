import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/api_call.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/session/session_currency.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/categories/categories.dart';
import 'package:spendyholik/features/recurring/data/api/recurring_api.dart';
import 'package:spendyholik/features/recurring/data/models/models.dart';
import 'package:spendyholik/features/recurring/data/models/recurring_dtos.dart';
import 'package:spendyholik/features/recurring/data/repositories/recurring_repository.dart';
import 'package:spendyholik/features/transactions/transactions.dart';
import 'package:talker/talker.dart';

@LazySingleton(as: RecurringRepository)
class RemoteRecurringRepository implements RecurringRepository {
  RemoteRecurringRepository(
    this._api,
    this._reader,
    this._bus,
    this._session,
    this._talker,
  );

  static const _fields = {
    'name': 'title',
    'amount_minor': 'amount',
    'account_id': 'accountId',
    'category_id': 'categoryId',
    'anchor_date': 'anchor',
  };

  static final _day = DateFormat('yyyy-MM-dd');

  final RecurringApi _api;
  final CachedReader _reader;
  final DataChangeBus _bus;
  final SessionCurrency _session;
  final Talker _talker;

  @override
  Future<List<RecurringModel>> getAll() async {
    final dtos = await _reader.read(
      key: cacheKey('recurring'),
      fetch: () => _call(_api.list),
      toJson: (list) => [for (final dto in list) dto.toJson()],
      fromJson: (json) => [
        for (final item in json! as List)
          RecurringOutDto.fromJson(item as Map<String, dynamic>),
      ],
    );
    final all = dtos.map(_model).toList();
    return [
      ...all.where((r) => !r.isPaused).toList()
        ..sort((a, b) => a.nextDate.compareTo(b.nextDate)),
      ...all.where((r) => r.isPaused),
    ];
  }

  @override
  Future<RecurringModel> create(RecurringDraft draft) async {
    final created = await _call(
      () => _api.create(
        RecurringCreateBody(
          name: draft.title,
          amountMinor: draft.amount,
          type: draft.type.name,
          accountId: draft.accountId,
          frequency: draft.frequency.name,
          categoryId: draft.categoryId,
          anchorDate: _day.format(draft.anchor),
        ),
      ),
      _fields,
    );
    _bus.emit({DataTopic.recurring});
    return _model(created);
  }

  /// Тип при правке не уходит: в PATCH поля `type` нет.
  @override
  Future<RecurringModel> update(String id, RecurringDraft draft) async {
    final updated = await _call(
      () => _api.update(
        id,
        RecurringPatchBody(
          name: draft.title,
          amountMinor: draft.amount,
          accountId: draft.accountId,
          categoryId: draft.categoryId,
          frequency: draft.frequency.name,
          anchorDate: _day.format(draft.anchor),
        ),
      ),
      _fields,
    );
    _bus.emit({DataTopic.recurring});
    return _model(updated);
  }

  @override
  Future<RecurringModel> setPaused(String id, bool paused) async {
    final updated = await _call(
      () => _api.toggle(id, RecurringToggleBody(isActive: !paused)),
    );
    _bus.emit({DataTopic.recurring});
    return _model(updated);
  }

  RecurringModel _model(RecurringOutDto dto) {
    final nextDate = _noon(dto.nextRun);
    final account = dto.account;
    final category = dto.category;
    return RecurringModel(
      id: dto.id,
      currency: _currency(dto.amount.currency),
      title: dto.name,
      type:
          TransactionType.values.asNameMap()[dto.type] ??
          TransactionType.expense,
      amount: dto.amount.minor,
      // У сервера категории может не быть (удалена) — запасная ссылка с пустым
      // id: форма правки видит её как «не выбрана».
      category: switch (category) {
        final ref? => CategoryRef(
          id: ref.id,
          name: ref.name ?? '',
          icon: EntityIcon.values.asNameMap()[ref.icon] ?? EntityIcon.other,
          color: EntityColor.values.asNameMap()[ref.color] ?? EntityColor.gray,
        ),
        null => const CategoryRef(
          id: '',
          name: '',
          icon: EntityIcon.other,
          color: EntityColor.gray,
        ),
      },
      account: AccountRef(
        id: account?.id ?? dto.accountId,
        name: account?.name ?? '',
        color:
            EntityColor.values.asNameMap()[account?.color] ?? EntityColor.gray,
      ),
      frequency:
          RecurrenceFrequency.values.asNameMap()[dto.frequency] ??
          RecurrenceFrequency.monthly,
      anchor: switch (dto.anchorDate) {
        final date? => _noon(date),
        null => nextDate,
      },
      nextDate: nextDate,
      isPaused: !dto.isActive,
    );
  }

  /// Полдень, как в форме: сдвиг часового пояса не переносит дату.
  static DateTime _noon(String date) {
    final day = DateTime.parse(date);
    return DateTime(day.year, day.month, day.day, 12);
  }

  Currency _currency(String code) {
    final currency = Currency.fromCode(code);
    if (currency != null) return currency;
    _talker.warning('Unknown recurring currency $code, using base');
    return _session.value;
  }

  Future<T> _call<T>(
    Future<T> Function() request, [
    Map<String, String> fields = const {},
  ]) => callApi(request, fields: fields);
}
