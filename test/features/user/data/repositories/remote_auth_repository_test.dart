import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/network/auth_tokens.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/email_verification_required.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/network/session_expiry.dart';
import 'package:spendyholik/core/network/token_storage.dart';
import 'package:spendyholik/core/session/session_currency.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/user/data/api/auth_api.dart';
import 'package:spendyholik/features/user/data/models/auth_dtos.dart';
import 'package:spendyholik/features/user/data/models/user_model.dart';
import 'package:spendyholik/features/user/data/repositories/remote_auth_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../helpers/dio_errors.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockApiCache extends Mock implements ApiCache {}

class MockDataChangeBus extends Mock implements DataChangeBus {}

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

const confirmedUser = ConfirmedUserDto(
  id: 'u1',
  firstName: 'Мария',
  email: 'maria@example.com',
  emailVerified: true,
);

void main() {
  late MockAuthApi api;
  late MockTokenStorage tokens;
  late SessionExpiry expiry;
  late MockApiCache cache;
  late SessionCurrency sessionCurrency;
  late MockDataChangeBus bus;
  late EmailVerificationRequired verification;
  late RemoteAuthRepository repository;

  final stored = AuthTokens(
    access: 'a',
    refresh: 'r',
    accessExpiresAt: DateTime.utc(2026),
    refreshExpiresAt: DateTime.utc(2026),
  );

  setUpAll(() {
    registerFallbackValue(<DataTopic>{});
    registerFallbackValue(const LoginBody(email: '', password: ''));
    registerFallbackValue(
      const RegisterBody(
        email: '',
        password: '',
        firstName: '',
        personalDataConsent: true,
      ),
    );
    registerFallbackValue(const RefreshBody(refreshToken: ''));
    registerFallbackValue(const ConfirmEmailBody(code: ''));
    registerFallbackValue(const ProfilePatchBody());
    registerFallbackValue(const PasswordBody(code: '', newPassword: ''));
    registerFallbackValue(const RequestPasswordResetBody(email: ''));
    registerFallbackValue(
      const ConfirmPasswordResetBody(email: '', code: '', newPassword: ''),
    );
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
    when(() => cache.generation).thenReturn(0);
    repository = RemoteAuthRepository(
      api,
      tokens,
      expiry,
      CachedReader(cache, NetworkStatus(), Talker()),
      cache,
      sessionCurrency = SessionCurrency(),
      Talker(settings: TalkerSettings(useConsoleLogs: false)),
      bus = MockDataChangeBus(),
      verification = EmailVerificationRequired(),
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
      await repository.register(
        'Мария',
        'maria@example.com',
        'secret-12',
        personalDataConsent: true,
      );
      final body =
          verify(() => api.register(captureAny())).captured.single
              as RegisterBody;
      expect(body.firstName, 'Мария');
      expect(body.toJson()['personal_data_consent'], isTrue);

      when(() => api.register(any()))
          .thenThrow(apiError(409, 'email_already_taken'));
      await expectLater(
        repository.register(
          'Мария',
          'maria@example.com',
          'secret-12',
          personalDataConsent: true,
        ),
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

  test(
    'requestPasswordChangeCode — POST за кодом; часто — RateLimited',
    () async {
      when(() => api.requestPasswordChangeCode()).thenAnswer((_) async {});
      await repository.requestPasswordChangeCode();
      verify(() => api.requestPasswordChangeCode()).called(1);

      when(() => api.requestPasswordChangeCode())
          .thenThrow(apiError(429, 'resend_too_soon'));
      await expectLater(
        repository.requestPasswordChangeCode(),
        throwsA(isA<RateLimitedFailure>()),
      );
    },
  );

  test(
    'changePassword: тело {code, new_password}; неверный код — у поля code',
    () async {
      when(() => api.changePassword(any()))
          .thenThrow(apiError(422, 'invalid_code', {'code': 'invalid_code'}));

      await expectLater(
        repository.changePassword('000000', 'new-secret'),
        throwsA(
          isA<ValidationFailure>()
              .having((f) => f.field, 'field', 'code')
              .having((f) => f.reason, 'reason', FieldError.invalidCode),
        ),
      );
      final body =
          verify(() => api.changePassword(captureAny())).captured.single
              as PasswordBody;
      expect(body.toJson(), {'code': '000000', 'new_password': 'new-secret'});
    },
  );

  test(
    'changePassword: сервер отозвал все сессии — новый вход с новым паролем',
    () async {
      when(() => tokens.read()).thenAnswer((_) async => stored);
      await repository.restoreSession();
      when(() => api.changePassword(any())).thenAnswer((_) async {});
      when(() => api.login(any())).thenAnswer((_) async => auth);

      await repository.changePassword('482913', 'new-secret');

      final body =
          verify(() => api.login(captureAny())).captured.single as LoginBody;
      expect(body.email, 'maria@example.com');
      expect(body.password, 'new-secret');
      final saved =
          verify(() => tokens.write(captureAny())).captured.last as AuthTokens;
      expect(saved.refresh, 'ref');
    },
  );

  test(
    'смена базовой валюты — итоги перезагружаются (сервер их пересчитал)',
    () async {
      when(() => api.updateProfile(any())).thenAnswer((_) async => profile);

      await repository.setBaseCurrency(Currency.usd);

      verify(
        () => bus.emit({
          DataTopic.accounts,
          DataTopic.budgets,
          DataTopic.transactions,
        }),
      ).called(1);
    },
  );

  test('смена имени и email — итоги не трогаются', () async {
    when(() => api.updateProfile(any())).thenAnswer((_) async => profile);

    await repository.updateProfile(name: 'Мария', email: 'm@example.com');

    verifyNever(() => bus.emit(any()));
  });

  test('профиль не того формата — UnknownFailure (Splash не висит)', () async {
    when(() => tokens.read()).thenAnswer((_) async => stored);
    when(() => api.profile()).thenThrow(TypeError());

    await expectLater(
      repository.restoreSession(),
      throwsA(isA<UnknownFailure>()),
    );
  });

  test('вход — кэш прежнего пользователя стёрт до записи токенов', () async {
    when(() => api.login(any())).thenAnswer((_) async => auth);

    await repository.signIn('maria@example.com', 'secret-1');

    verifyInOrder([() => cache.clear(), () => tokens.write(any())]);
  });

  test('регистрация — кэш стёрт', () async {
    when(() => api.register(any())).thenAnswer((_) async => auth);

    await repository.register(
      'Мария',
      'maria@example.com',
      'secret-12',
      personalDataConsent: true,
    );

    verify(() => cache.clear()).called(1);
  });

  test('токенов нет — кэш стёрт: без сессии чужие данные не нужны', () async {
    when(() => tokens.read()).thenAnswer((_) async => null);

    await repository.restoreSession();

    verify(() => cache.clear()).called(1);
  });

  group('подтверждение почты', () {
    test(
      'профиль: email_verified → emailVerified; без поля в старом кэше — true',
      () async {
        when(() => tokens.read()).thenAnswer((_) async => stored);
        when(() => api.profile()).thenAnswer(
          (_) async => ProfileOutDto.fromJson(const {
            'user_id': 'u1',
            'first_name': 'Мария',
            'email': 'm@example.com',
            'email_verified': false,
          }),
        );

        expect((await repository.restoreSession())!.emailVerified, isFalse);
        expect(
          ProfileOutDto.fromJson(const {
            'user_id': 'u1',
            'first_name': 'М',
            'email': 'm@example.com',
          }).emailVerified,
          isTrue,
        );
      },
    );

    test('confirmEmail — код на сервер, ответ публикуется в userChanges', () async {
      when(() => api.confirmEmail(any())).thenAnswer((_) async => confirmedUser);
      final changes = expectLater(repository.userChanges, emits(isNotNull));

      final user = await repository.confirmEmail('482913');

      final body =
          verify(() => api.confirmEmail(captureAny())).captured.single
              as ConfirmEmailBody;
      expect(body.code, '482913');
      expect(user.id, 'u1');
      await changes;
    });

    test('успешное подтверждение не зависит от доступности GET профиля', () async {
      when(() => tokens.read()).thenAnswer((_) async => stored);
      when(() => api.profile()).thenAnswer((_) async => const ProfileOutDto(
        userId: 'u1',
        firstName: 'Мария',
        email: 'maria@example.com',
        baseCurrency: 'USD',
        emailVerified: false,
      ));
      expect((await repository.restoreSession())?.emailVerified, isFalse);
      verify(() => api.profile()).called(1);
      when(() => api.confirmEmail(any())).thenAnswer((_) async => confirmedUser);
      when(() => api.profile()).thenThrow(networkError());

      final user = await repository.confirmEmail('482913');

      expect(user.emailVerified, isTrue);
      expect(user.baseCurrency, Currency.usd);
      verifyNever(() => api.profile());
      verify(() => cache.write(
        ApiCache.profileKey,
        any(that: contains('"email_verified":true')),
      )).called(1);
    });

    test('confirmEmail после подтверждения на другом устройстве обновляет сессию', () async {
      when(() => api.confirmEmail(any()))
          .thenThrow(apiError(409, 'email_already_verified'));
      final changes = <UserModel?>[];
      final subscription = repository.userChanges.listen(changes.add);
      addTearDown(subscription.cancel);

      expect((await repository.confirmEmail('482913')).emailVerified, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(changes.single?.emailVerified, isTrue);
      verify(() => api.profile()).called(1);
    });

    test('resendEmailCode после подтверждения на другом устройстве обновляет сессию', () async {
      when(() => api.resendEmailCode())
          .thenThrow(apiError(409, 'email_already_verified'));
      final changes = <UserModel?>[];
      final subscription = repository.userChanges.listen(changes.add);
      addTearDown(subscription.cancel);

      expect(await repository.resendEmailCode(), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(changes.single?.emailVerified, isTrue);
      verify(() => api.profile()).called(1);
    });

    test('confirmEmail: неверный код — ошибка у поля code', () async {
      when(() => api.confirmEmail(any()))
          .thenThrow(apiError(422, 'invalid_code', {'code': 'invalid_code'}));

      await expectLater(
        repository.confirmEmail('000000'),
        throwsA(
          isA<ValidationFailure>()
              .having((f) => f.field, 'field', 'code')
              .having((f) => f.reason, 'reason', FieldError.invalidCode),
        ),
      );
    });

    test('resendEmailCode — POST; слишком рано — RateLimitedFailure', () async {
      when(() => api.resendEmailCode()).thenAnswer((_) async {});
      expect(await repository.resendEmailCode(), isFalse);
      verify(() => api.resendEmailCode()).called(1);

      when(() => api.resendEmailCode())
          .thenThrow(apiError(429, 'resend_too_soon'));
      await expectLater(
        repository.resendEmailCode(),
        throwsA(isA<RateLimitedFailure>()),
      );
    });

    test('регистрация: нет согласия — ошибка у поля consent', () async {
      when(() => api.register(any())).thenThrow(
        apiError(422, 'validation_error', {
          'personal_data_consent': 'required',
        }),
      );

      await expectLater(
        repository.register(
          'Мария',
          'maria@example.com',
          'secret-12',
          personalDataConsent: false,
        ),
        throwsA(
          isA<ValidationFailure>().having((f) => f.field, 'field', 'consent'),
        ),
      );
    });
  });

  test('сервер закрыл данные (403) — профиль заново, userChanges без подтверждения', () async {
    when(() => tokens.read()).thenAnswer((_) async => stored);
    when(() => api.profile()).thenAnswer(
      (_) async => ProfileOutDto.fromJson(const {
        'user_id': 'u1',
        'first_name': 'Мария',
        'email': 'new@example.com',
        'email_verified': false,
      }),
    );
    final changes = expectLater(
      repository.userChanges,
      emits(
        isA<Object>().having(
          (u) => (u as dynamic).emailVerified,
          'verified',
          false,
        ),
      ),
    );

    verification.notify();

    await changes;
  });

  group('смена email', () {
    test(
      'с текущим паролем — current_password в теле; без — ключа нет',
      () async {
        when(() => api.updateProfile(any())).thenAnswer((_) async => profile);

        await repository.updateProfile(
          name: 'Мария',
          email: 'new@example.com',
          currentPassword: 'secret-1',
        );
        await repository.updateProfile(
          name: 'Мария',
          email: 'maria@example.com',
        );

        final bodies = verify(() => api.updateProfile(captureAny())).captured
            .cast<ProfilePatchBody>();
        expect(bodies.first.toJson()['current_password'], 'secret-1');
        expect(bodies.last.toJson().containsKey('current_password'), isFalse);
      },
    );

    test('неверный текущий пароль — ошибка у currentPassword', () async {
      when(() => api.updateProfile(any())).thenThrow(
        apiError(422, 'wrong_password', {'current_password': 'wrong_password'}),
      );

      await expectLater(
        repository.updateProfile(
          name: 'Мария',
          email: 'new@example.com',
          currentPassword: 'nope',
        ),
        throwsA(
          isA<ValidationFailure>()
              .having((f) => f.field, 'field', 'currentPassword')
              .having((f) => f.reason, 'reason', FieldError.wrongPassword),
        ),
      );
    });
  });

  test('requestPasswordReset: тело {email}; 429 — RateLimited', () async {
    when(() => api.requestPasswordReset(any())).thenAnswer((_) async {});
    await repository.requestPasswordReset('maria@example.com');
    final body =
        verify(() => api.requestPasswordReset(captureAny())).captured.single
            as RequestPasswordResetBody;
    expect(body.toJson(), {'email': 'maria@example.com'});

    when(() => api.requestPasswordReset(any()))
        .thenThrow(apiError(429, 'resend_too_soon'));
    await expectLater(
      repository.requestPasswordReset('maria@example.com'),
      throwsA(isA<RateLimitedFailure>()),
    );
  });

  test('confirmPasswordReset: тело {email, code, new_password}; неверный код — у code', () async {
    when(() => api.confirmPasswordReset(any()))
        .thenThrow(apiError(422, 'invalid_code', {'code': 'invalid_code'}));

    await expectLater(
      repository.confirmPasswordReset(
        'maria@example.com',
        '000000',
        'pw-12345',
      ),
      throwsA(
        isA<ValidationFailure>()
            .having((f) => f.field, 'field', 'code')
            .having((f) => f.reason, 'reason', FieldError.invalidCode),
      ),
    );
    final body =
        verify(() => api.confirmPasswordReset(captureAny())).captured.single
            as ConfirmPasswordResetBody;
    expect(body.toJson(), {
      'email': 'maria@example.com',
      'code': '000000',
      'new_password': 'pw-12345',
    });
    verifyNever(() => api.login(any()));
  });
}
