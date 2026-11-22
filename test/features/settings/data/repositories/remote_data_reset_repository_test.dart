import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/core/storage/cache_entry.dart';
import 'package:spendyholik/core/storage/hive_api_cache.dart';
import 'package:spendyholik/features/settings/data/api/data_reset_api.dart';
import 'package:spendyholik/features/settings/data/repositories/remote_data_reset_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

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
    when(() => cache.generation).thenReturn(0);
    bus = MockDataChangeBus();
    when(() => cache.clear(keep: any(named: 'keep'))).thenAnswer((_) async {});
    repository = RemoteDataResetRepository(api, cache, bus);
  });

  test('wipeAll зовёт API, чистит кэш и сообщает всем темам', () async {
    when(() => api.wipeData()).thenAnswer((_) async {});

    await repository.wipeAll();

    verifyInOrder([
      () => api.wipeData(),
      () => cache.clear(keep: {ApiCache.profileKey}),
      () => bus.emit(DataTopic.values.toSet()),
    ]);
  });

  test('ошибка API: Failure, кэш не тронут, темам не сообщено', () async {
    when(() => api.wipeData()).thenThrow(apiError(500, 'server_error'));

    await expectLater(repository.wipeAll(), throwsA(isA<Failure>()));

    verifyZeroInteractions(cache);
    verifyNever(() => bus.emit(any()));
  });

  test('после удаления данных и переоткрытия кэша профиль доступен', () async {
    final dir = await Directory.systemTemp.createTemp('data_reset_cache');
    Hive.init(dir.path);
    Hive.registerAdapter(CacheEntryAdapter());
    addTearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });
    final storage = HiveApiCache(Hive, Talker());
    await storage.write('profile', '{"email_verified":true}');
    await storage.write('accounts', '[1]');
    when(() => api.wipeData()).thenAnswer((_) async {});

    await RemoteDataResetRepository(api, storage, bus).wipeAll();
    await Hive.close();
    final reopened = HiveApiCache(Hive, Talker());

    expect(await reopened.read('profile'), '{"email_verified":true}');
    expect(await reopened.read('accounts'), isNull);
  });

  test('без сети: NetworkFailure', () async {
    when(() => api.wipeData()).thenThrow(networkError());

    await expectLater(repository.wipeAll(), throwsA(isA<NetworkFailure>()));

    verifyZeroInteractions(cache);
  });
}
