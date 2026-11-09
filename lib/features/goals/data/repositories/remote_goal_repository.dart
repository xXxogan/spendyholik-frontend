import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/api_call.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/session/session_currency.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/goals/data/api/goals_api.dart';
import 'package:spendyholik/features/goals/data/models/goal_dtos.dart';
import 'package:spendyholik/features/goals/data/models/models.dart';
import 'package:spendyholik/features/goals/data/repositories/goal_repository.dart';
import 'package:talker/talker.dart';

@LazySingleton(as: GoalRepository)
class RemoteGoalRepository implements GoalRepository {
  RemoteGoalRepository(
    this._api,
    this._reader,
    this._bus,
    this._session,
    this._talker,
  );

  static const _formFields = {
    'name': 'name',
    'target_amount_minor': 'target',
    'initial_amount_minor': 'initialContribution',
    'account_id': 'initialAccountId',
  };
  static const _topUpFields = {
    'amount_minor': 'amount',
    'account_id': 'accountId',
  };

  static final _day = DateFormat('yyyy-MM-dd');

  final GoalsApi _api;
  final CachedReader _reader;
  final DataChangeBus _bus;
  final SessionCurrency _session;
  final Talker _talker;

  @override
  Future<List<GoalModel>> getGoals() async {
    final dtos = await _reader.read(
      key: cacheKey('goals'),
      fetch: () => _call(_api.list),
      toJson: (list) => [for (final dto in list) dto.toJson()],
      fromJson: (json) => [
        for (final item in json! as List)
          GoalOutDto.fromJson(item as Map<String, dynamic>),
      ],
    );
    return dtos.map(_goal).toList();
  }

  @override
  Future<GoalModel> getGoal(String id) async => _goal(
    await _reader.read(
      key: cacheKey('goals/$id'),
      fetch: () => _call(() => _api.get(id)),
      toJson: (dto) => dto.toJson(),
      fromJson: (json) => GoalOutDto.fromJson(json! as Map<String, dynamic>),
    ),
  );

  @override
  Future<List<GoalContribution>> getContributions(String goalId) async {
    final dtos = await _reader.read(
      key: cacheKey('goals/$goalId/contributions'),
      fetch: () => _call(() => _api.contributions(goalId)),
      toJson: (list) => [for (final dto in list) dto.toJson()],
      fromJson: (json) => [
        for (final item in json! as List)
          ContributionOutDto.fromJson(item as Map<String, dynamic>),
      ],
    );
    return dtos.map(_contribution).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Без кэша: прогноз зависит от «сегодня», вчерашний был бы неверным.
  @override
  Future<DateTime?> getForecast(String goalId) async {
    final dto = await _call(() => _api.forecast(goalId));
    return switch (dto.projectedCompletion) {
      final date? => DateTime.parse(date),
      null => null,
    };
  }

  @override
  Future<GoalModel> create(GoalDraft draft) async {
    final created = await _call(
      () => _api.create(
        GoalCreateBody(
          name: draft.name,
          targetAmountMinor: draft.target,
          // Выбора валюты в форме нет: новая цель — в базовой (решение 2026-11-07).
          currency: _session.value.code,
          accountId: draft.initialAccountId,
          initialAmountMinor: draft.initialContribution,
          deadline: _date(draft.deadline),
        ),
      ),
      _formFields,
    );
    _bus.emit({DataTopic.goals, DataTopic.accounts});
    return _goal(created);
  }

  @override
  Future<GoalModel> update(String id, GoalDraft draft) async {
    final updated = await _call(
      () => _api.update(
        id,
        GoalPatchBody(
          name: draft.name,
          targetAmountMinor: draft.target,
          deadline: _date(draft.deadline),
        ),
      ),
      _formFields,
    );
    _bus.emit({DataTopic.goals});
    return _goal(updated);
  }

  @override
  Future<void> delete(String id) async {
    await _call(() => _api.delete(id));
    // Пополнения удаляются с целью — деньги возвращаются на счета.
    _bus.emit({DataTopic.goals, DataTopic.accounts});
  }

  @override
  Future<void> contribute(
    String goalId,
    int amount,
    String accountId,
  ) async {
    await _call(
      () => _api.contribute(
        goalId,
        ContributeBody(
          accountId: accountId,
          amountMinor: amount,
          date: _day.format(DateTime.now()),
        ),
      ),
      _topUpFields,
    );
    // Шина сразу после записи: перечитывание цели здесь могло упасть уже после
    // списания — пользователь увидел бы ошибку, а повтор пополнил бы дважды.
    _bus.emit({DataTopic.goals, DataTopic.accounts});
  }

  GoalModel _goal(GoalOutDto dto) => GoalModel(
    id: dto.id,
    currency: _currency(dto.targetAmount.currency),
    name: dto.name,
    target: dto.targetAmount.minor,
    saved: dto.currentAmount.minor,
    deadline: switch (dto.deadline) {
      final date? => DateTime.parse(date),
      null => null,
    },
  );

  GoalContribution _contribution(ContributionOutDto dto) => GoalContribution(
    id: dto.id,
    amount: dto.amount.minor,
    from: switch (dto.account) {
      final ref? => AccountRef(
        id: ref.id,
        name: ref.name,
        color: EntityColor.values.asNameMap()[ref.color] ?? EntityColor.gray,
      ),
      null => AccountRef(
        id: dto.accountId ?? '',
        name: '',
        color: EntityColor.gray,
      ),
    },
    date: DateTime.parse(dto.date),
  );

  Currency _currency(String code) {
    final currency = Currency.fromCode(code);
    if (currency != null) return currency;
    _talker.warning('Unknown goal currency $code, using base');
    return _session.value;
  }

  static String? _date(DateTime? date) =>
      date == null ? null : _day.format(date);

  Future<T> _call<T>(
    Future<T> Function() request, [
    Map<String, String> fields = const {},
  ]) => callApi(request, fields: fields);
}
