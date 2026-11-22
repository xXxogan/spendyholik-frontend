import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/api_call.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/features/budgets/data/api/budgets_api.dart';
import 'package:spendyholik/features/budgets/data/models/budget_dtos.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/features/budgets/data/repositories/budget_repository.dart';
import 'package:spendyholik/features/categories/categories.dart';

@LazySingleton(as: BudgetRepository)
class RemoteBudgetRepository implements BudgetRepository {
  RemoteBudgetRepository(this._api, this._reader, this._bus);

  static const _fields = {
    'category_id': 'categoryId',
    'amount_minor': 'limit',
    // Отдельных полей дат у формы нет: даты разового бюджета — в выборе периода.
    'start_date': 'period',
    'end_date': 'period',
  };

  static const _changedTopics = {DataTopic.budgets};

  static final _day = DateFormat('yyyy-MM-dd');

  final BudgetsApi _api;
  final CachedReader _reader;
  final DataChangeBus _bus;

  @override
  Future<List<BudgetModel>> getBudgets() async {
    final dtos = await _reader.read(
      key: cacheKey('budgets'),
      fetch: () => _call(_api.list),
      toJson: (list) => [for (final dto in list) dto.toJson()],
      fromJson: (json) => [
        for (final item in json! as List)
          BudgetOutDto.fromJson(item as Map<String, dynamic>),
      ],
    );
    return dtos.map(_budget).toList();
  }

  @override
  Future<BudgetModel> getBudget(String id) async => _budget(
    await _reader.read(
      key: cacheKey('budgets/$id'),
      fetch: () => _call(() => _api.get(id)),
      toJson: (dto) => dto.toJson(),
      fromJson: (json) => BudgetOutDto.fromJson(json! as Map<String, dynamic>),
    ),
  );

  @override
  Future<BudgetModel> create(BudgetDraft draft) async {
    final created = await _call(
      () => _api.create(
        BudgetCreateBody(
          categoryId: draft.categoryId,
          amountMinor: draft.limit,
          period: _periodName(draft.period),
          startDate: _startDate(draft),
          endDate: _endDate(draft),
          isActive: true,
        ),
      ),
    );
    _bus.emit(_changedTopics);
    return _budget(created);
  }

  @override
  Future<BudgetModel> update(String id, BudgetDraft draft) async {
    final updated = await _call(
      () => _api.update(
        id,
        BudgetPatchBody(
          categoryId: draft.categoryId,
          amountMinor: draft.limit,
          period: _periodName(draft.period),
          startDate: _startDate(draft),
          endDate: _endDate(draft),
        ),
      ),
    );
    _bus.emit(_changedTopics);
    return _budget(updated);
  }

  @override
  Future<void> delete(String id) async {
    await _call(() => _api.delete(id));
    _bus.emit(_changedTopics);
  }

  String? _startDate(BudgetDraft draft) => switch (draft.onceStart) {
    final start? when draft.period == .once => _day.format(start),
    _ => null,
  };

  /// В модели конец не включительный, а `end_date` сервера — последний день.
  String? _endDate(BudgetDraft draft) => switch (draft.onceEnd) {
    final end? when draft.period == .once => _day.format(
      DateTime(end.year, end.month, end.day - 1),
    ),
    _ => null,
  };

  String _periodName(BudgetPeriod period) => switch (period) {
    .monthly => 'monthly',
    .weekly => 'weekly',
    .once => 'one_time',
  };

  BudgetModel _budget(BudgetOutDto dto) {
    final period = switch (dto.period) {
      'weekly' => BudgetPeriod.weekly,
      'one_time' => BudgetPeriod.once,
      _ => BudgetPeriod.monthly,
    };
    final ref = dto.category;
    return BudgetModel(
      id: dto.id,
      category: CategoryRef(
        id: ref.id,
        name: ref.name ?? '',
        icon: EntityIcon.values.asNameMap()[ref.icon] ?? EntityIcon.other,
        color: EntityColor.values.asNameMap()[ref.color] ?? EntityColor.gray,
      ),
      limit: dto.amount.minor,
      spent: dto.spent.minor,
      period: period,
      currentPeriod: _currentPeriod(dto, period),
    );
  }

  /// `period_end` включительный, `DatePeriod.end` — нет. Без `period_*`
  /// (неактивный бюджет) берём заданные даты, иначе текущий месяц или неделю.
  DatePeriod _currentPeriod(BudgetOutDto dto, BudgetPeriod period) {
    final start = dto.periodStart ?? dto.startDate;
    final end = dto.periodEnd ?? dto.endDate;
    if (start != null && end != null) {
      final last = DateTime.parse(end);
      return DatePeriod(
        start: DateTime.parse(start),
        end: DateTime(last.year, last.month, last.day + 1),
      );
    }
    return DatePeriod.current(
      period == .weekly ? PeriodPreset.week : PeriodPreset.month,
      DateTime.now(),
    );
  }

  Future<T> _call<T>(Future<T> Function() request) =>
      callApi(request, fields: _fields);
}
