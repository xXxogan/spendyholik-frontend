import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/categories/categories.dart';
import 'package:spendyholik/features/recurring/data/models/recurring_model.dart';
import 'package:spendyholik/features/recurring/data/repositories/recurring_repository.dart';
import 'package:spendyholik/features/recurring/presentation/cubit/recurring_cubit.dart';
import 'package:spendyholik/features/transactions/transactions.dart';

class MockRecurringRepository extends Mock implements RecurringRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

RecurringModel template(String id, {bool paused = false}) => RecurringModel(
  id: id,
  title: 'Шаблон $id',
  type: TransactionType.expense,
  amount: 4500000,
  category: const CategoryRef(
    id: 'cat-housing',
    name: 'Жильё',
    icon: EntityIcon.home,
    color: EntityColor.blue,
  ),
  account: const AccountRef(
    id: 'acc-savings',
    name: 'Накопительный',
    color: EntityColor.green,
  ),
  frequency: RecurrenceFrequency.monthly,
  anchor: DateTime(2026, 1, 1),
  nextDate: DateTime(2026, 12),
  isPaused: paused,
);

void main() {
  late MockRecurringRepository repository;
  late MockDataChangeBus bus;
  late StreamController<Set<DataTopic>> changes;

  final rent = template('rent');
  final gym = template('gym', paused: true);

  setUp(() {
    repository = MockRecurringRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  RecurringCubit build() => RecurringCubit(repository, bus);

  blocTest<RecurringCubit, RecurringState>(
    'загрузка: loading → шаблоны',
    setUp: () =>
        when(() => repository.getAll()).thenAnswer((_) async => [rent, gym]),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const RecurringState.loading(),
      RecurringState.loaded([rent, gym]),
    ],
  );

  blocTest<RecurringCubit, RecurringState>(
    'шаблонов нет — empty',
    setUp: () => when(() => repository.getAll()).thenAnswer((_) async => []),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const RecurringState.loading(),
      const RecurringState.empty(),
    ],
  );

  blocTest<RecurringCubit, RecurringState>(
    'ошибка репозитория — error',
    setUp: () =>
        when(() => repository.getAll()).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const RecurringState.loading(),
      const RecurringState.error(NetworkFailure()),
    ],
  );

  blocTest<RecurringCubit, RecurringState>(
    'togglePause: setPaused с обратным значением и перезагрузка',
    setUp: () {
      var calls = 0;
      when(() => repository.getAll()).thenAnswer(
        (_) async =>
            ++calls == 1 ? [rent, gym] : [template('rent', paused: true), gym],
      );
      when(() => repository.setPaused('rent', true))
          .thenAnswer((_) async => template('rent', paused: true));
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.togglePause('rent');
    },
    skip: 2,
    expect: () => [
      isA<RecurringLoaded>().having(
        (s) => s.templates.first.isPaused,
        'rent paused',
        true,
      ),
    ],
    verify: (_) {
      verify(() => repository.setPaused('rent', true)).called(1);
      verify(() => repository.getAll()).called(2);
    },
  );

  blocTest<RecurringCubit, RecurringState>(
    'ошибка паузы — error',
    setUp: () {
      when(() => repository.getAll()).thenAnswer((_) async => [rent]);
      when(() => repository.setPaused('rent', true))
          .thenThrow(const NetworkFailure());
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.togglePause('rent');
    },
    skip: 2,
    expect: () => [const RecurringState.error(NetworkFailure())],
  );

  blocTest<RecurringCubit, RecurringState>(
    'изменение в шине — тихая перезагрузка',
    setUp: () {
      var calls = 0;
      when(() => repository.getAll())
          .thenAnswer((_) async => ++calls == 1 ? [rent] : [rent, gym]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      changes.add({DataTopic.recurring});
      await Future<void>.delayed(Duration.zero);
    },
    skip: 2,
    expect: () => [
      RecurringState.loaded([rent, gym]),
    ],
  );
}
