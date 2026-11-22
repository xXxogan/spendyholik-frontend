import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/app/router/guards.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/user/data/models/user_model.dart';
import 'package:spendyholik/features/user/presentation/cubit/session_cubit.dart';

class MockSessionCubit extends MockCubit<SessionState>
    implements SessionCubit {}

class MockResolver extends Mock implements NavigationResolver {}

class MockStackRouter extends Mock implements StackRouter {}

const withCurrency = UserModel(
  id: 'u1',
  name: 'Мария',
  email: 'maria@example.com',
  baseCurrency: Currency.rub,
);

const withoutCurrency = UserModel(
  id: 'u1',
  name: 'Мария',
  email: 'maria@example.com',
);

const unverified = UserModel(
  id: 'u2',
  name: 'Иван',
  email: 'ivan@example.com',
  emailVerified: false,
);

void main() {
  group('authRedirect', () {
    test('нет сессии — login', () {
      expect(
        authRedirect(const SessionState.unauthenticated(onboardingSeen: true))
            ?.routeName,
        LoginRoute.name,
      );
    });

    test(
      'онбординг не видел — тоже login: на вкладки без входа не попасть',
      () {
        expect(
          authRedirect(
            const SessionState.unauthenticated(onboardingSeen: false),
          )?.routeName,
          LoginRoute.name,
        );
      },
    );

    test('валюты нет — currency', () {
      expect(
        authRedirect(const SessionState.authenticated(withoutCurrency))
            ?.routeName,
        CurrencyRoute.name,
      );
    });

    test('всё есть — пропустить', () {
      expect(
        authRedirect(const SessionState.authenticated(withCurrency)),
        isNull,
      );
    });
  });

  group('sessionRedirect', () {
    test('сессия без валюты — пропустить', () {
      expect(
        sessionRedirect(const SessionState.authenticated(withoutCurrency)),
        isNull,
      );
    });

    test('нет сессии — login', () {
      expect(
        sessionRedirect(
          const SessionState.unauthenticated(onboardingSeen: true),
        )?.routeName,
        LoginRoute.name,
      );
    });
  });

  group('splashRoute', () {
    test('сессия ещё восстанавливается — оставаться на Splash', () {
      expect(splashRoute(const SessionState.unknown()), isNull);
    });

    test('онбординг не видел — onboarding, видел — login', () {
      expect(
        splashRoute(const SessionState.unauthenticated(onboardingSeen: false))
            ?.routeName,
        OnboardingRoute.name,
      );
      expect(
        splashRoute(const SessionState.unauthenticated(onboardingSeen: true))
            ?.routeName,
        LoginRoute.name,
      );
    });

    test('нет валюты — currency, всё есть — Home', () {
      expect(
        splashRoute(const SessionState.authenticated(withoutCurrency))
            ?.routeName,
        CurrencyRoute.name,
      );
      expect(
        splashRoute(const SessionState.authenticated(withCurrency))?.routeName,
        HomeRoute.name,
      );
    });
  });

  group('deepLinkNext', () {
    test('прямая ссылка — запомнить, чтобы открыть после Splash', () {
      expect(deepLinkNext('/accounts'), '/accounts');
      expect(deepLinkNext('/budgets/bud-cafe?x=1'), '/budgets/bud-cafe?x=1');
    });

    test('корень и сам Splash — обычный старт', () {
      expect(deepLinkNext(''), isNull);
      expect(deepLinkNext('/'), isNull);
      expect(deepLinkNext('/splash'), isNull);
      expect(deepLinkNext('/splash?next=%2Faccounts'), isNull);
    });
  });

  test('прямая ссылка на политику доступна до входа и подтверждения почты', () {
    expect(canFollowNext(const OnboardingRoute(), '/privacy'), isTrue);
    expect(canFollowNext(const LoginRoute(), '/privacy'), isTrue);
    expect(canFollowNext(const EmailConfirmRoute(), '/privacy'), isTrue);
  });

  group('AuthGuard', () {
    late MockSessionCubit session;
    late MockResolver resolver;
    late MockStackRouter router;

    setUpAll(() => registerFallbackValue(<PageRouteInfo>[]));

    setUp(() {
      session = MockSessionCubit();
      resolver = MockResolver();
      router = MockStackRouter();
      when(() => router.replaceAll(any())).thenAnswer((_) async {});
    });

    test('сессия ещё восстанавливается — ждёт и пропускает', () async {
      whenListen(
        session,
        Stream.value(const SessionState.authenticated(withCurrency)),
        initialState: const SessionState.unknown(),
      );

      await AuthGuard(session).check(resolver, router);

      verify(() => resolver.next()).called(1);
      verifyNever(() => router.replaceAll(any()));
    });

    test('нет сессии — отменяет переход и ведёт на login', () async {
      when(() => session.state)
          .thenReturn(const SessionState.unauthenticated(onboardingSeen: true));

      await AuthGuard(session).check(resolver, router);

      verify(() => resolver.next(false)).called(1);
      final routes =
          verify(() => router.replaceAll(captureAny())).captured.single
              as List<PageRouteInfo>;
      expect(routes.single.routeName, LoginRoute.name);
    });
  });

  group('guestRedirect', () {
    test('нет сессии — пропустить на вход и регистрацию', () {
      expect(
        guestRedirect(const SessionState.unauthenticated(onboardingSeen: true)),
        isNull,
      );
    });

    test('вошедший — на Главную', () {
      expect(
        guestRedirect(const SessionState.authenticated(withCurrency))
            ?.routeName,
        HomeRoute.name,
      );
    });

    test('вошедший без валюты — на выбор валюты', () {
      expect(
        guestRedirect(const SessionState.authenticated(withoutCurrency))
            ?.routeName,
        CurrencyRoute.name,
      );
    });
  });

  group('canFollowNext', () {
    test('на Главную — любой сохранённый адрес', () {
      expect(canFollowNext(const HomeRoute(), '/accounts'), isTrue);
    });

    test('на вход — только регистрация', () {
      expect(canFollowNext(const LoginRoute(), '/register'), isTrue);
      expect(canFollowNext(const LoginRoute(), '/accounts'), isFalse);
    });

    test('онбординг и выбор валюты адрес не продолжают', () {
      expect(canFollowNext(const OnboardingRoute(), '/register'), isFalse);
      expect(canFollowNext(const CurrencyRoute(), '/accounts'), isFalse);
    });
  });

  group('почта не подтверждена (круг 3)', () {
    const state = SessionState.authenticated(unverified);

    test('вкладки, выбор валюты, Splash и гостевые — на экран кода', () {
      expect(authRedirect(state), isA<EmailConfirmRoute>());
      expect(sessionRedirect(state), isA<EmailConfirmRoute>());
      expect(splashRoute(state), isA<EmailConfirmRoute>());
      expect(guestRedirect(state), isA<EmailConfirmRoute>());
    });

    test('экран кода: неподтверждённого пропускает, подтверждённого — дальше, без сессии — вход', () {
      expect(emailConfirmRedirect(state), isNull);
      expect(
        emailConfirmRedirect(const SessionState.authenticated(withCurrency)),
        isA<HomeRoute>(),
      );
      expect(
        emailConfirmRedirect(
          const SessionState.unauthenticated(onboardingSeen: true),
        ),
        isA<LoginRoute>(),
      );
    });
  });
}
