import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/network/auth_tokens.dart';
import 'package:spendyholik/core/network/secure_token_storage.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

final tokens = AuthTokens(
  access: 'a',
  refresh: 'r',
  accessExpiresAt: DateTime.utc(2026, 11, 7, 12),
  refreshExpiresAt: DateTime.utc(2026, 12, 7, 12),
);

void main() {
  late MockSecureStorage secure;
  late SecureTokenStorage storage;
  final saved = <String, String>{};

  setUp(() {
    saved.clear();
    secure = MockSecureStorage();
    when(
      () => secure.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((i) async {
      saved[i.namedArguments[#key] as String] =
          i.namedArguments[#value] as String;
    });
    when(() => secure.read(key: any(named: 'key')))
        .thenAnswer((i) async => saved[i.namedArguments[#key]]);
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((i) async {
      saved.remove(i.namedArguments[#key]);
    });
    storage = SecureTokenStorage(secure);
  });

  test('write → read: та же пара, одна запись под одним ключом', () async {
    await storage.write(tokens);

    expect(saved, hasLength(1));
    final read = await storage.read();
    expect(read?.access, 'a');
    expect(read?.refresh, 'r');
    expect(read?.refreshExpiresAt, DateTime.utc(2026, 12, 7, 12));
  });

  test('ничего не записано — null', () async {
    expect(await storage.read(), isNull);
  });

  test(
    'чтение бросает не-Exception (Web OperationError) — null и очистка',
    () async {
      when(() => secure.read(key: any(named: 'key')))
          .thenThrow('OperationError');

      expect(await storage.read(), isNull);
      verify(() => secure.delete(key: any(named: 'key'))).called(1);
    },
  );

  test('мусор в хранилище — null', () async {
    saved['auth.tokens'] = '{not json';
    expect(await storage.read(), isNull);
  });

  test('параллельные записи идут по очереди', () async {
    final gate = Completer<void>();
    var active = 0;
    var maxActive = 0;
    when(
      () => secure.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {
      active++;
      maxActive = active > maxActive ? active : maxActive;
      await gate.future;
      active--;
    });

    final writes = Future.wait([storage.write(tokens), storage.write(tokens)]);
    await Future<void>.delayed(Duration.zero);
    gate.complete();
    await writes;

    expect(maxActive, 1);
  });
}
