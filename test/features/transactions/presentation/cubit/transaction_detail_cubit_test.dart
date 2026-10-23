import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/entity_color.dart';
import 'package:spendyholik/features/accounts/data/models/account_model.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/repositories/repositories.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transaction_detail_cubit.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

void main() {
  late MockTransactionRepository repository;
  late MockDataChangeBus bus;
  late StreamController<Set<DataTopic>> changes;

  final transaction = TransactionModel(
    id: 't1',
    type: TransactionType.transfer,
    amount: 500000,
    title: '',
    account: const AccountRef(id: 'a', name: 'Карта', color: EntityColor.blue),
    toAccount: const AccountRef(
      id: 'b',
      name: 'Вклад',
      color: EntityColor.green,
    ),
    occurredAt: DateTime(2026, 10, 20, 12, 30),
  );

  setUp(() {
    repository = MockTransactionRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
    when(() => repository.getTransaction('t1'))
        .thenAnswer((_) async => transaction);
  });

  tearDown(() => changes.close());

  TransactionDetailCubit build() => TransactionDetailCubit(repository, bus);

  blocTest<TransactionDetailCubit, TransactionDetailState>(
    'загрузка: операция',
    build: build,
    act: (cubit) => cubit.load('t1'),
    expect: () => [
      const TransactionDetailState.loading(),
      TransactionDetailState.loaded(transaction),
    ],
  );

  blocTest<TransactionDetailCubit, TransactionDetailState>(
    'NotFound при загрузке — error',
    setUp: () =>
        when(() => repository.getTransaction('t1'))
            .thenAnswer((_) async => throw const NotFoundFailure()),
    build: build,
    act: (cubit) => cubit.load('t1'),
    expect: () => [
      const TransactionDetailState.loading(),
      const TransactionDetailState.error(NotFoundFailure()),
    ],
  );

  blocTest<TransactionDetailCubit, TransactionDetailState>(
    'delete — deleted, репозиторий вызван',
    setUp: () => when(() => repository.delete('t1')).thenAnswer((_) async {}),
    build: build,
    act: (cubit) async {
      await cubit.load('t1');
      await cubit.delete();
    },
    skip: 2,
    expect: () => [const TransactionDetailState.deleted()],
    verify: (_) => verify(() => repository.delete('t1')).called(1),
  );

  blocTest<TransactionDetailCubit, TransactionDetailState>(
    'ошибка удаления — error',
    setUp: () =>
        when(() => repository.delete('t1'))
            .thenAnswer((_) async => throw const NetworkFailure()),
    build: build,
    act: (cubit) async {
      await cubit.load('t1');
      await cubit.delete();
    },
    skip: 2,
    expect: () => [const TransactionDetailState.error(NetworkFailure())],
  );

  blocTest<TransactionDetailCubit, TransactionDetailState>(
    'изменение по шине в loaded — тихая перезагрузка',
    build: build,
    act: (cubit) async {
      await cubit.load('t1');
      changes.add({DataTopic.transactions});
      await Future<void>.delayed(Duration.zero);
    },
    skip: 2,
    expect: () => <TransactionDetailState>[],
    verify: (_) => verify(() => repository.getTransaction('t1')).called(2),
  );

  blocTest<TransactionDetailCubit, TransactionDetailState>(
    'после deleted шина не вызывает загрузку',
    setUp: () => when(() => repository.delete('t1')).thenAnswer((_) async {}),
    build: build,
    act: (cubit) async {
      await cubit.load('t1');
      await cubit.delete();
      changes.add({DataTopic.transactions, DataTopic.accounts});
      await Future<void>.delayed(Duration.zero);
    },
    verify: (_) => verify(() => repository.getTransaction('t1')).called(1),
  );

  test('шина приходит раньше конца удаления (как у фейка) — без перезагрузки и ошибки', () async {
    final realBus = DataChangeBus();
    addTearDown(realBus.dispose);
    var deleted = false;
    when(() => repository.getTransaction('t1')).thenAnswer(
      (_) async => deleted ? throw const NotFoundFailure() : transaction,
    );
    when(() => repository.delete('t1')).thenAnswer((_) async {
      deleted = true;
      realBus.emit({DataTopic.transactions});
    });
    final cubit = TransactionDetailCubit(repository, realBus);
    final states = <TransactionDetailState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.load('t1');
    await cubit.delete();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();
    await cubit.close();

    expect(states.last, const TransactionDetailState.deleted());
    expect(states.whereType<TransactionDetailError>(), isEmpty);
    verify(() => repository.getTransaction('t1')).called(1);
  });
}
