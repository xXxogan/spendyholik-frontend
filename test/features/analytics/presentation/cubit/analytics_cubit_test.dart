import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/analytics/data/models/models.dart';
import 'package:spendyholik/features/analytics/data/repositories/repositories.dart';
import 'package:spendyholik/features/analytics/presentation/cubit/analytics_cubit.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';

class MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

CategoryShare share(String id, int amount, double share) => CategoryShare(
  category: CategoryRef(
    id: id,
    name: id,
    icon: EntityIcon.other,
    color: EntityColor.gray,
  ),
  amount: amount,
  share: share,
);

AnalyticsReport report({
  int income = 100000,
  int expense = 30000,
  List<CategoryShare> shares = const [],
}) => AnalyticsReport(
  period: DatePeriod(start: DateTime(2026, 10), end: DateTime(2026, 11)),
  income: income,
  expense: expense,
  expenseChange: 0.12,
  expenseByCategory: shares,
  trend: const [],
);

void main() {
  late MockAnalyticsRepository repository;
  late MockDataChangeBus bus;
  late StreamController<Set<DataTopic>> changes;

  setUpAll(() => registerFallbackValue(PeriodPreset.month));

  setUp(() {
    repository = MockAnalyticsRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  AnalyticsCubit build() => AnalyticsCubit(repository, bus);

  blocTest<AnalyticsCubit, AnalyticsState>(
    'load — отчёт за месяц по умолчанию',
    setUp: () =>
        when(() => repository.getReport(PeriodPreset.month))
            .thenAnswer((_) async => report()),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const AnalyticsState.loading(PeriodPreset.month),
      isA<AnalyticsLoaded>().having(
        (s) => s.preset,
        'preset',
        PeriodPreset.month,
      ),
    ],
  );

  blocTest<AnalyticsCubit, AnalyticsState>(
    'selectPeriod перезагружает отчёт за выбранный период',
    setUp: () =>
        when(() => repository.getReport(any()))
            .thenAnswer((_) async => report()),
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectPeriod(PeriodPreset.week);
    },
    skip: 2,
    expect: () => [
      const AnalyticsState.loading(PeriodPreset.week),
      isA<AnalyticsLoaded>().having(
        (s) => s.preset,
        'preset',
        PeriodPreset.week,
      ),
    ],
    verify: (_) =>
        verify(() => repository.getReport(PeriodPreset.week)).called(1),
  );

  blocTest<AnalyticsCubit, AnalyticsState>(
    'доли 33,3 / 33,3 / 33,3 — проценты в сумме 100',
    setUp: () => when(() => repository.getReport(any())).thenAnswer(
      (_) async => report(
        expense: 30000,
        shares: [
          share('a', 10000, 1 / 3),
          share('b', 10000, 1 / 3),
          share('c', 10000, 1 / 3),
        ],
      ),
    ),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      final percents = (cubit.state as AnalyticsLoaded).percents;
      expect(percents.reduce((a, b) => a + b), 100);
      expect(percents, [34, 33, 33]);
    },
  );

  blocTest<AnalyticsCubit, AnalyticsState>(
    'наибольший остаток получает лишний процент, а не первая категория',
    setUp: () => when(() => repository.getReport(any())).thenAnswer(
      (_) async => report(
        expense: 1000,
        shares: [
          share('a', 611, 0.611),
          share('b', 197, 0.197),
          share('c', 192, 0.192),
        ],
      ),
    ),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) =>
        expect((cubit.state as AnalyticsLoaded).percents, [61, 20, 19]),
  );

  blocTest<AnalyticsCubit, AnalyticsState>(
    'нет операций за период — empty',
    setUp: () =>
        when(() => repository.getReport(any()))
            .thenAnswer((_) async => report(income: 0, expense: 0)),
    build: build,
    act: (cubit) => cubit.selectPeriod(PeriodPreset.year),
    expect: () => [
      const AnalyticsState.loading(PeriodPreset.year),
      const AnalyticsState.empty(PeriodPreset.year),
    ],
  );

  blocTest<AnalyticsCubit, AnalyticsState>(
    'ошибка — error с текущим периодом',
    setUp: () =>
        when(() => repository.getReport(any()))
            .thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const AnalyticsState.loading(PeriodPreset.month),
      const AnalyticsState.error(NetworkFailure(), PeriodPreset.month),
    ],
  );

  blocTest<AnalyticsCubit, AnalyticsState>(
    'изменились операции — перезагрузка того же периода без loading',
    setUp: () =>
        when(() => repository.getReport(any()))
            .thenAnswer((_) async => report()),
    build: build,
    act: (cubit) async {
      await cubit.selectPeriod(PeriodPreset.year);
      changes.add({DataTopic.transactions});
      await Future<void>.delayed(Duration.zero);
    },
    skip: 2,
    expect: () => [isA<AnalyticsLoaded>()],
    verify: (_) =>
        verify(() => repository.getReport(PeriodPreset.year)).called(2),
  );
}
