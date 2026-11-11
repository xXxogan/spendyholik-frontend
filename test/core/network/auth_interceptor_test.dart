import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/core/network/api_interceptors.dart';
import 'package:spendyholik/core/network/auth_tokens.dart';
import 'package:spendyholik/core/network/email_verification_required.dart';
import 'package:spendyholik/core/network/session_expiry.dart';
import 'package:spendyholik/core/network/token_storage.dart';

class _MemoryTokens implements TokenStorage {
  _MemoryTokens(this.value);

  AuthTokens? value;

  @override
  Future<AuthTokens?> read() async => value;

  @override
  Future<void> write(AuthTokens tokens) async => value = tokens;

  @override
  Future<void> clear() async => value = null;
}

AuthTokens _pair(String access, String refresh) => AuthTokens(
  access: access,
  refresh: refresh,
  accessExpiresAt: DateTime.utc(2026),
  refreshExpiresAt: DateTime.utc(2026),
);

/// Сервер: действует только [validAccess]; refresh выдаёт `new`/`ref2`.
class _Server implements HttpClientAdapter {
  String validAccess = 'acc';
  int refreshStatus = 200;
  int refreshCalls = 0;
  final seen = <String, Object?>{};
  Completer<void>? holdRefresh;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final auth = options.headers['Authorization'];
    seen[options.path] = auth;
    if (options.path == 'auth/refresh/') {
      refreshCalls++;
      await holdRefresh?.future;
      if (refreshStatus != 200) return _json(refreshStatus, {'code': 'x'});
      validAccess = 'new';
      return _json(200, {
        'access': 'new',
        'refresh': 'ref2',
        'access_expires_at': '2026-11-07T10:00:00Z',
        'refresh_expires_at': '2026-12-07T10:00:00Z',
      });
    }
    if (options.path == 'locked/') {
      return _json(403, {
        'code': 'email_not_verified',
        'detail': 'd',
        'errors': {},
      });
    }
    if (options.path.startsWith('auth/')) return _json(401, {'code': 'x'});
    if (auth != 'Bearer $validAccess') return _json(401, {'code': 'x'});
    return _json(200, {'path': options.path});
  }

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  late _MemoryTokens tokens;
  late _Server server;
  late SessionExpiry expiry;
  late EmailVerificationRequired verification;
  late Dio dio;

  setUp(() {
    tokens = _MemoryTokens(_pair('acc', 'ref'));
    server = _Server();
    expiry = SessionExpiry();
    verification = EmailVerificationRequired();
    final options = BaseOptions(baseUrl: 'https://api.test/api/v1/');
    final plain = Dio(options)..httpClientAdapter = server;
    dio = Dio(options)
      ..httpClientAdapter = server
      ..interceptors.add(AuthInterceptor(tokens, expiry, verification, plain));
  });

  test('обычный запрос — Bearer из хранилища', () async {
    await dio.get<void>('profile/');
    expect(server.seen['profile/'], 'Bearer acc');
  });

  test('вход и регистрация — без токена', () async {
    server.validAccess = 'other';
    await expectLater(
      dio.post<void>('auth/login/'),
      throwsA(isA<DioException>()),
    );
    await expectLater(
      dio.post<void>('auth/register/'),
      throwsA(isA<DioException>()),
    );
    expect(server.seen['auth/login/'], isNull);
    expect(server.seen['auth/register/'], isNull);
  });

  test('токенов нет — запрос уходит без заголовка', () async {
    tokens.value = null;
    await expectLater(dio.get<void>('profile/'), throwsA(isA<DioException>()));
    expect(server.seen['profile/'], isNull);
  });

  test('401 → refresh → повтор с новым access, пара сохранена', () async {
    server.validAccess = 'new';
    final response = await dio.get<Map<String, dynamic>>('profile/');
    expect(response.data, {'path': 'profile/'});
    expect(server.refreshCalls, 1);
    expect(server.seen['profile/'], 'Bearer new');
    expect(tokens.value?.access, 'new');
    expect(tokens.value?.refresh, 'ref2');
  });

  test('три параллельных 401 — один refresh, все запросы повторены', () async {
    server.validAccess = 'new';
    final responses = await Future.wait([
      dio.get<Map<String, dynamic>>('accounts/'),
      dio.get<Map<String, dynamic>>('dashboard/'),
      dio.get<Map<String, dynamic>>('profile/'),
    ]);
    expect(server.refreshCalls, 1);
    expect(responses.map((r) => r.statusCode), [200, 200, 200]);
  });

  test(
    'запрос со старым access после refresh — повтор без второго refresh',
    () async {
      server
        ..validAccess = 'new'
        ..holdRefresh = Completer();
      final first = dio.get<void>('accounts/');
      await pumpEventQueue();
      // Второй запрос ушёл со старым access, пока refresh ещё не вернулся.
      final second = dio.get<void>('dashboard/');
      await pumpEventQueue();
      server.holdRefresh!.complete();
      await Future.wait([first, second]);
      expect(server.refreshCalls, 1);
      expect(server.seen['dashboard/'], 'Bearer new');
    },
  );

  test(
    'refresh отклонён — токены стёрты, сессия истекла, наружу 401',
    () async {
      server
        ..validAccess = 'new'
        ..refreshStatus = 401;
      var expired = 0;
      expiry.expired.listen((_) => expired++);
      await expectLater(
        dio.get<void>('profile/'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );
      await pumpEventQueue();
      expect(tokens.value, isNull);
      expect(expired, 1);
    },
  );

  test('refresh не дошёл (5xx) — токены остаются', () async {
    server
      ..validAccess = 'new'
      ..refreshStatus = 503;
    var expired = 0;
    expiry.expired.listen((_) => expired++);
    await expectLater(dio.get<void>('profile/'), throwsA(isA<DioException>()));
    await pumpEventQueue();
    expect(tokens.value?.refresh, 'ref');
    expect(expired, 0);
  });

  test('401 на auth/login не запускает refresh', () async {
    await expectLater(
      dio.post<void>('auth/login/'),
      throwsA(isA<DioException>()),
    );
    expect(server.refreshCalls, 0);
  });

  test(
    'выход — без Bearer: просроченный access не должен запускать refresh',
    () async {
      server.validAccess = 'new';
      await expectLater(
        dio.post<void>('auth/logout/', data: {'refresh_token': 'ref'}),
        throwsA(isA<DioException>()),
      );
      expect(server.seen['auth/logout/'], isNull);
      expect(server.refreshCalls, 0);
    },
  );

  test(
    '403 email_not_verified — сигнал «нужно подтвердить почту», ошибка дальше',
    () async {
      var signals = 0;
      verification.required.listen((_) => signals++);

      await expectLater(
        dio.get<void>('locked/'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            403,
          ),
        ),
      );
      await pumpEventQueue();

      expect(signals, 1);
      expect(server.refreshCalls, 0);
    },
  );
}
