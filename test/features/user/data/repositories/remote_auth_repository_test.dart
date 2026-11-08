import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/auth_tokens.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/network/session_expiry.dart';
import 'package:spendyholik/core/network/token_storage.dart';
import 'package:spendyholik/core/session/session_currency.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/user/data/api/auth_api.dart';
import 'package:spendyholik/features/user/data/models/auth_dtos.dart';
import 'package:spendyholik/features/user/data/repositories/remote_auth_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../helpers/dio_errors.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockApiCache extends Mock implements ApiCache {}

final auth = AuthOutDto(
  access: 'acc',
  refresh: 'ref',
  accessExpiresAt: DateTime.utc(2026, 11, 7, 12, 15),
  refreshExpiresAt: DateTime.utc(2026, 12, 7),
);

const profile = ProfileOutDto(
  userId: 'u1',
  firstName: 'Мария',
  email: 'maria@example.com',
  baseCurrency: 'RUB',
);

void main() {
  late MockAuthApi api;
  late MockTokenStorage tokens;
  late SessionExpiry expiry;
  late MockApiCache cache;
  late SessionCurrency sessionCurrency;
  late RemoteAuthRepository repository;

  final stored = AuthTokens(
    access: 'a',
    refresh: 'r',
    accessExpiresAt: DateTime.utc(2026),
    refreshExpiresAt: DateTime.utc(2026),
  );

  setUpAll(() {
    registerFallbackValue(const LoginBody(email: '', password: ''));
    registerFallbackValue(
      const RegisterBody(email: '', password: '', firstName: ''),
    );
    registerFallbackValue(const RefreshBody(refreshToken: ''));
    registerFallbackValue(const ProfilePatchBody());
    registerFallbackValue(const PasswordBody(oldPassword: '', newPassword: ''));
    registerFallbackValue(
      AuthTokens(
        access: '',
        refresh: '',
        accessExpiresAt: DateTime.utc(2026),
        refreshExpiresAt: DateTime.utc(2026),
      ),
    );
  });

  setUp(() {
    api = MockAuthApi();
    tokens = MockTokenStorage();
    when(() => tokens.write(any())).thenAnswer((_) async {});
    when(() => tokens.clear()).thenAnswer((_) async {});
    when(() => api.profile()).thenAnswer((_) async => profile);
    expiry = SessionExpiry();
    cache = MockApiCache();
    when(() => cache.read(any())).thenAnswer((_) async => null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    when(() => cache.clear()).thenAnswer((_) async {});
    repository = RemoteAuthRepository(
      api,
      tokens,
      expiry,
      CachedReader(cache, NetworkStatus(), Talker()),
      cache,
      sessionCurrency = SessionCurrency(),
    );
  });

  test(
    'refresh отклонён (SessionExpiry) — userChanges null, кэш стёрт',
    () async {
      final changes = expectLater(repository.userChanges, emits(isNull));
      expiry.notify();
      await changes;
      verify(() => cache.clear()).called(1);
    },
  );

  group('signIn', () {
    test('токены сохранены, пользователь из профиля, userChanges', () async {
      when(() => api.login(any())).thenAnswer((_) async => auth);
      final changes = expectLater(
        repository.userChanges,
        emits(isA<Object>().having((u) => (u as dynamic).id, 'id', 'u1')),
      );

      final user = await repository.signIn('maria@example.com', 'secret-1');

      expect(user.name, 'Мария');
      expect(user.baseCurrency, Currency.rub);
      final saved =
          verify(() => tokens.write(captureAny())).captured.single
              as AuthTokens;
      expect(saved.access, 'acc');
      expect(saved.refresh, 'ref');
      await changes;
    });

    test(
      'неверная пара — InvalidCredentialsFailure, токены не пишутся',
      () async {
        when(() => api.login(any()))
            .thenThrow(apiError(401, 'invalid_credentials'));

        await expectLater(
          repository.signIn('a@b.c', 'x'),
          throwsA(isA<InvalidCredentialsFailure>()),
        );
        verifyNever(() => tokens.write(any()));
      },
    );

    test('нет сети — NetworkFailure', () async {
      when(() => api.login(any())).thenThrow(networkError());

      await expectLater(
        repository.signIn('a@b.c', 'x'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('restoreSession', () {
    test('токенов нет — null, профиль не запрашивается', () async {
      when(() => tokens.read()).thenAnswer((_) async => null);

      expect(await repository.restoreSession(), isNull);
      verifyNever(() => api.profile());
    });

    test(
      'токены есть — пользователь; без валюты — baseCurrency null',
      () async {
        when(() => tokens.read()).thenAnswer(
          (_) async => AuthTokens(
            access: 'a',
            refresh: 'r',
            accessExpiresAt: DateTime.utc(2026),
            refreshExpiresAt: DateTime.utc(2026),
          ),
        );
        when(() => api.profile()).thenAnswer(
          (_) async => const ProfileOutDto(
            userId: 'u1',
            firstName: 'Мария',
            email: 'maria@example.com',
          ),
        );

        final user = await repository.restoreSession();
        expect(user?.id, 'u1');
        expect(user?.baseCurrency, isNull);
      },
    );

    test('сервер не принял токен — null и токены стёрты', () async {
      when(() => tokens.read()).thenAnswer(
        (_) async => AuthTokens(
          access: 'a',
          refresh: 'r',
          accessExpiresAt: DateTime.utc(2026),
          refreshExpiresAt: DateTime.utc(2026),
        ),
      );
      when(() => api.profile()).thenThrow(apiError(401, 'token_invalid'));

      expect(await repository.restoreSession(), isNull);
      verify(() => tokens.clear()).called(1);
    });

    test(
      'валюта пользователя — базовая валюта сессии для репозиториев',
      () async {
        when(() => tokens.read()).thenAnswer((_) async => stored);
        when(() => api.profile()).thenAnswer(
          (_) async => const ProfileOutDto(
            userId: 'u1',
            firstName: 'Мария',
            email: 'm@example.com',
            baseCurrency: 'USD',
          ),
        );
        await repository.restoreSession();
        expect(sessionCurrency.value, Currency.usd);

        when(() => api.updateProfile(any())).thenAnswer((_) async => profile);
        await repository.setBaseCurrency(Currency.rub);
        expect(sessionCurrency.value, Currency.rub);
      },
    );

    test('профиль загружен — он в кэше', () async {
      when(() => tokens.read()).thenAnswer((_) async => stored);
      await repository.restoreSession();
      final json =
          verify(() => cache.write('profile', captureAny())).captured.single
              as String;
      expect(json, contains('"first_name":"Мария"'));
    });

    test('нет сети, профиль в кэше — пользователь из кэша', () async {
      when(() => tokens.read()).thenAnswer((_) async => stored);
      when(() => api.profile()).thenThrow(networkError());
      when(() => cache.read('profile')).thenAnswer(
        (_) async =>
            '{"user_id":"u1","first_name":"Мария","email":"m@example.com",'
            '"base_currency":"RUB"}',
      );

      final user = await repository.restoreSession();
      expect(user?.id, 'u1');
      expect(user?.baseCurrency, Currency.rub);
      verifyNever(() => tokens.clear());
    });

    test('нет сети, кэша нет — NetworkFailure, токены целы', () async {
      when(() => tokens.read()).thenAnswer((_) async => stored);
      when(() => api.profile()).thenThrow(networkError());

      await expectLater(
        repository.restoreSession(),
        throwsA(isA<NetworkFailure>()),
      );
      verifyNever(() => tokens.clear());
    });
  });

  test(
    'register: имя уходит в first_name; занятый email — EmailTakenFailure',
    () async {
      when(() => api.register(any())).thenAnswer((_) async => auth);
      await repository.register('Мария', 'maria@example.com', 'secret-12');
      final body =
          verify(() => api.register(captureAny())).captured.single
              as RegisterBody;
      expect(body.firstName, 'Мария');

      when(() => api.register(any()))
          .thenThrow(apiError(409, 'email_already_taken'));
      await expectLater(
        repository.register('Мария', 'maria@example.com', 'secret-12'),
        throwsA(isA<EmailTakenFailure>()),
      );
    },
  );

  test('signOut: refresh отозван, токены стёрты, userChanges null — даже если logout упал', () async {
    when(() => tokens.read()).thenAnswer(
      (_) async => AuthTokens(
        access: 'a',
        refresh: 'ref',
        accessExpiresAt: DateTime.utc(2026),
        refreshExpiresAt: DateTime.utc(2026),
      ),
    );
    when(() => api.logout(any())).thenThrow(networkError());
    final changes = expectLater(repository.userChanges, emits(isNull));

    await repository.signOut();

    final body =
        verify(() => api.logout(captureAny())).captured.single as RefreshBody;
    expect(body.refreshToken, 'ref');
    verify(() => tokens.clear()).called(1);
    verify(() => cache.clear()).called(1);
    await changes;
  });

  test(
    'updateProfile и setBaseCurrency — PATCH profile, userChanges',
    () async {
      when(() => api.updateProfile(any())).thenAnswer((_) async => profile);
      final changes = expectLater(
        repository.userChanges,
        emitsInOrder([isNotNull, isNotNull]),
      );

      await repository.updateProfile(name: 'Мария', email: 'maria@example.com');
      await repository.setBaseCurrency(Currency.usd);

      final bodies = verify(() => api.updateProfile(captureAny())).captured
          .cast<ProfilePatchBody>();
      expect(bodies.first.toJson(), {
        'first_name': 'Мария',
        'email': 'maria@example.com',
      });
      expect(bodies.last.toJson(), {'base_currency': 'USD'});
      // Без сети после правки должен показаться новый профиль, а не старый.
      verify(() => cache.write('profile', any())).called(2);
      await changes;
    },
  );

  test('changePassword: wrong_password — ошибка у currentPassword', () async {
    when(() => api.changePassword(any())).thenThrow(
      apiError(422, 'validation_error', {'old_password': 'wrong_password'}),
    );

    await expectLater(
      repository.changePassword('old', 'new-secret'),
      throwsA(
        isA<ValidationFailure>()
            .having((f) => f.field, 'field', 'currentPassword')
            .having((f) => f.reason, 'reason', FieldError.wrongPassword),
      ),
    );
  });
}
