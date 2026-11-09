import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/settings/data/api/data_reset_api.dart';
import 'package:spendyholik/features/settings/data/repositories/remote_data_reset_repository.dart';

import '../../../../helpers/dio_errors.dart';

class MockDataResetApi extends Mock implements DataResetApi {}

class MockApiCache extends Mock implements ApiCache {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

void main() {
  late MockDataResetApi api;
  late MockApiCache cache;
  late MockDataChangeBus bus;
  late RemoteDataResetRepository repository;

  setUpAll(() => registerFallbackValue(<DataTopic>{}));

  setUp(() {
    api = MockDataResetApi();
    cache = MockApiCache();
    bus = MockDataChangeBus();
    when(() => cache.clear()).thenAnswer((_) async {});
    repository = RemoteDataResetRepository(api, cache, bus);
  });

  test('wipeAll зовёт API, чистит кэш и сообщает всем темам', () async {
    when(() => api.wipeData()).thenAnswer((_) async {});

    await repository.wipeAll();

    verifyInOrder([
      () => api.wipeData(),
      () => cache.clear(),
      () => bus.emit(DataTopic.values.toSet()),
    ]);
  });

  test('ошибка API: Failure, кэш не тронут, темам не сообщено', () async {
    when(() => api.wipeData()).thenThrow(apiError(500, 'server_error'));

    await expectLater(repository.wipeAll(), throwsA(isA<Failure>()));

    verifyNever(() => cache.clear());
    verifyNever(() => bus.emit(any()));
  });

  test('без сети: NetworkFailure', () async {
    when(() => api.wipeData()).thenThrow(networkError());

    await expectLater(repository.wipeAll(), throwsA(isA<NetworkFailure>()));

    verifyNever(() => cache.clear());
  });
}
