import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/settings/data/repositories/fake_data_reset_repository.dart';

class MockDataChangeBus extends Mock implements DataChangeBus {}

void main() {
  setUpAll(() => registerFallbackValue(<DataTopic>{}));

  test(
    'wipeAll чистит данные, оставляет пользователя и сообщает всем темам',
    () async {
      final backend = FakeBackend();
      final bus = MockDataChangeBus();
      final user = backend.user;
      final credentials = List.of(backend.accountsOfUsers);
      expect(backend.accounts, isNotEmpty);

      await FakeDataResetRepository(backend, bus).wipeAll();

      expect(backend.accounts, isEmpty);
      expect(backend.transactions, isEmpty);
      expect(backend.categories, isEmpty);
      expect(backend.budgets, isEmpty);
      expect(backend.goals, isEmpty);
      expect(backend.recurring, isEmpty);
      expect(backend.debts, isEmpty);
      expect(backend.notifications, isEmpty);
      expect(backend.user, user);
      expect(backend.accountsOfUsers, credentials);
      verify(() => bus.emit(DataTopic.values.toSet())).called(1);
    },
  );
}
