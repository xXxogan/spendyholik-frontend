import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockApiCache extends Mock implements ApiCache {}

void main() {
  late MockApiCache cache;
  late NetworkStatus status;
  late CachedReader reader;

  Future<List<String>> read(Future<List<String>> Function() fetch) =>
      reader.read(
        key: 'accounts',
        fetch: fetch,
        toJson: (names) => names,
        fromJson: (json) => (json! as List).cast<String>(),
      );

  setUp(() {
    cache = MockApiCache();
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    when(() => cache.read(any())).thenAnswer((_) async => null);
    status = NetworkStatus();
    reader = CachedReader(cache, status, Talker());
  });

  tearDown(() => status.close());

  group('cacheKey', () {
    test('путь без query — как есть', () {
      expect(cacheKey('accounts'), 'accounts');
    });

    test('query отсортирован, null отброшены', () {
      expect(
        cacheKey('transactions', {
          'type': 'expense',
          'account_id': 'a1',
          'cursor': null,
        }),
        'transactions?account_id=a1&type=expense',
      );
      expect(
        cacheKey('transactions', {'account_id': 'a1', 'type': 'expense'}),
        cacheKey('transactions', {'type': 'expense', 'account_id': 'a1'}),
      );
    });
  });

  test('успех — ответ в кэш, сеть есть', () async {
    status.reportOffline();
    final result = await read(() async => ['Карта']);
    expect(result, ['Карта']);
    verify(() => cache.write('accounts', '["Карта"]')).called(1);
    expect(status.state, isTrue);
  });

  test('нет сети, есть кэш — данные из кэша, сети нет', () async {
    when(() => cache.read('accounts')).thenAnswer((_) async => '["Наличные"]');
    final result = await read(() async => throw const NetworkFailure());
    expect(result, ['Наличные']);
    expect(status.state, isFalse);
  });

  test('нет сети, кэша нет — NetworkFailure', () async {
    await expectLater(
      read(() async => throw const NetworkFailure()),
      throwsA(isA<NetworkFailure>()),
    );
    expect(status.state, isFalse);
  });

  test('кэш не читается (схема сменилась) — NetworkFailure', () async {
    when(() => cache.read('accounts')).thenAnswer((_) async => '{"x":1}');
    await expectLater(
      read(() async => throw const NetworkFailure()),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('другая ошибка — кэш не читается, ошибка дальше', () async {
    await expectLater(
      read(() async => throw const UnknownFailure()),
      throwsA(isA<UnknownFailure>()),
    );
    verifyNever(() => cache.read(any()));
    expect(status.state, isTrue);
  });
}
