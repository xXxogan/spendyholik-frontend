import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/analytics/data/models/models.dart';
import 'package:spendyholik/features/analytics/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'analytics_cubit.freezed.dart';
part 'analytics_state.dart';

@injectable
class AnalyticsCubit extends Cubit<AnalyticsState>
    with CubitLogging<AnalyticsState> {
  AnalyticsCubit(this._repository, DataChangeBus bus)
    : super(const AnalyticsState.loading(PeriodPreset.month)) {
    _changes = bus.changes
        .where(
          (topics) =>
              topics.contains(DataTopic.transactions) ||
              topics.contains(DataTopic.categories),
        )
        .listen((_) {
          // Отчёты других периодов устарели: при переключении — снова с сервера.
          _shown.clear();
          load();
        });
  }

  final AnalyticsRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;

  /// Последний показанный отчёт каждого периода: повторное переключение
  /// показывает его сразу и обновляет тихо, без скелетона.
  final _shown = <PeriodPreset, AnalyticsState>{};

  PeriodPreset get _preset => switch (state) {
    AnalyticsLoading(:final preset) ||
    AnalyticsLoaded(:final preset) ||
    AnalyticsEmpty(:final preset) ||
    AnalyticsError(:final preset) => preset,
  };

  /// Перезагрузка текущего периода: по шине — тихо, без скелетона.
  Future<void> load() => _load(_preset, silent: state is AnalyticsLoaded);

  Future<void> selectPeriod(PeriodPreset preset) {
    final shown = _shown[preset];
    if (shown != null) emit(shown);
    return _load(preset, silent: shown != null);
  }

  Future<void> _load(PeriodPreset preset, {required bool silent}) async {
    if (!silent) emit(AnalyticsState.loading(preset));
    try {
      final report = await _repository.getReport(preset);
      if (preset != _preset) return;
      final next = report.income == 0 && report.expense == 0
          ? AnalyticsState.empty(preset)
          : AnalyticsState.loaded(
              report,
              preset,
              _percents([for (final s in report.expenseByCategory) s.share]),
            );
      _shown[preset] = next;
      emit(next);
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      if (preset != _preset) return;
      // Отчёт уже на экране — ошибка тихого обновления его не прячет.
      if (silent && (state is AnalyticsLoaded || state is AnalyticsEmpty)) {
        return;
      }
      emit(AnalyticsState.error(failure, preset));
    }
  }

  /// Метод наибольшего остатка: округляем вниз, недостающие до 100 процентов
  /// отдаём долям с наибольшей дробной частью.
  static List<int> _percents(List<double> shares) {
    if (shares.isEmpty) return const [];
    final raw = [for (final share in shares) share * 100];
    final result = [for (final value in raw) value.floor()];
    final missing = 100 - result.fold<int>(0, (sum, value) => sum + value);
    final byRemainder = List.generate(raw.length, (i) => i)
      ..sort((a, b) => (raw[b] - result[b]).compareTo(raw[a] - result[a]));
    for (final index in byRemainder.take(missing)) {
      result[index]++;
    }
    return result;
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
