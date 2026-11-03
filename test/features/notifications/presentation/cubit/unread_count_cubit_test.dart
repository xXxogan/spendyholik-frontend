import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/notifications/data/repositories/notification_repository.dart';
import 'package:spendyholik/features/notifications/presentation/cubit/unread_count_cubit.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

void main() {
  late MockNotificationRepository repository;
  late MockDataChangeBus bus;
  late StreamController<Set<DataTopic>> changes;

  setUp(() {
    repository = MockNotificationRepository();
    bus = MockDataChangeBus();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(() => bus.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  UnreadCountCubit build() => UnreadCountCubit(repository, bus);

  blocTest<UnreadCountCubit, int>(
    'загрузка — число непрочитанных',
    setUp: () =>
        when(() => repository.getUnreadCount()).thenAnswer((_) async => 2),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [2],
  );

  blocTest<UnreadCountCubit, int>(
    'прочитали в ленте — по шине счётчик уменьшается',
    setUp: () {
      var calls = 0;
      when(() => repository.getUnreadCount())
          .thenAnswer((_) async => ++calls == 1 ? 2 : 1);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      changes.add({DataTopic.budgets});
      changes.add({DataTopic.notifications});
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [2, 1],
  );

  blocTest<UnreadCountCubit, int>(
    'ошибка — счётчик остаётся прежним, без падения',
    setUp: () =>
        when(() => repository.getUnreadCount())
            .thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => <int>[],
  );
}
