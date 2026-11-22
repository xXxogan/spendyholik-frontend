import 'package:auto_route/auto_route.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/features/user/user.dart';

/// Куда увести с вкладок: нет сессии — на вход, почта не подтверждена — на
/// экран кода (сервер закрыт до него), нет валюты — на выбор валюты.
PageRouteInfo? authRedirect(SessionState state) => switch (state) {
  SessionAuthenticated(:final user) when !user.emailVerified =>
    const EmailConfirmRoute(),
  SessionAuthenticated(:final user) when user.baseCurrency == null =>
    const CurrencyRoute(),
  SessionAuthenticated() => null,
  SessionUnauthenticated() || SessionUnknown() => const LoginRoute(),
};

/// Выбору валюты нужна сессия с подтверждённой почтой: профиль без неё
/// сохранится, но дальше вкладок всё равно не пустит.
PageRouteInfo? sessionRedirect(SessionState state) => switch (state) {
  SessionAuthenticated(:final user) when !user.emailVerified =>
    const EmailConfirmRoute(),
  SessionAuthenticated() => null,
  SessionUnauthenticated() || SessionUnknown() => const LoginRoute(),
};

/// Вход и регистрация — только без сессии; вошедшего уводим дальше по сессии.
PageRouteInfo? guestRedirect(SessionState state) => switch (state) {
  SessionAuthenticated() => splashRoute(state),
  SessionUnauthenticated() || SessionUnknown() => null,
};

/// Куда уйти со Splash; null — сессия ещё восстанавливается.
PageRouteInfo? splashRoute(SessionState state) => switch (state) {
  SessionUnknown() => null,
  SessionUnauthenticated(onboardingSeen: false) => const OnboardingRoute(),
  SessionUnauthenticated() => const LoginRoute(),
  SessionAuthenticated(:final user) when !user.emailVerified =>
    const EmailConfirmRoute(),
  SessionAuthenticated(:final user) when user.baseCurrency == null =>
    const CurrencyRoute(),
  SessionAuthenticated() => const HomeRoute(),
};

/// Экран кода — только вошедшему с неподтверждённой почтой.
PageRouteInfo? emailConfirmRedirect(SessionState state) => switch (state) {
  SessionAuthenticated(:final user) when !user.emailVerified => null,
  SessionAuthenticated() => splashRoute(state),
  SessionUnauthenticated() || SessionUnknown() => const LoginRoute(),
};

/// Стартовый адрес, который откроется после Splash; null — обычный старт.
/// На Web прямая ссылка и обновление страницы иначе минуют Splash.
String? deepLinkNext(String path) {
  if (path.isEmpty || path == '/' || path.startsWith('/splash')) return null;
  return path;
}

/// Можно ли со Splash открыть сохранённый адрес [next] вместо [target].
bool canFollowNext(PageRouteInfo target, String next) {
  final uri = Uri.tryParse(next);
  if (uri != null && !uri.hasScheme && !uri.hasAuthority && uri.path == '/privacy') {
    return true;
  }
  return switch (target) {
    HomeRoute() => true,
    LoginRoute() => uri?.path == '/register',
    _ => false,
  };
}

abstract class _SessionAwareGuard extends AutoRouteGuard {
  _SessionAwareGuard(this._session);

  final SessionCubit _session;

  PageRouteInfo? redirect(SessionState state);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) =>
      check(resolver, router);

  /// На Web прямой URL приходит раньше, чем сессия восстановлена, —
  /// решаем после восстановления.
  Future<void> check(NavigationResolver resolver, StackRouter router) async {
    final state = _session.state is SessionUnknown
        ? await _session.stream.firstWhere((s) => s is! SessionUnknown)
        : _session.state;
    final target = redirect(state);
    if (target == null) {
      resolver.next();
    } else {
      resolver.next(false);
      await router.replaceAll([target]);
    }
  }
}

class AuthGuard extends _SessionAwareGuard {
  AuthGuard(super.session);

  @override
  PageRouteInfo? redirect(SessionState state) => authRedirect(state);
}

class SessionGuard extends _SessionAwareGuard {
  SessionGuard(super.session);

  @override
  PageRouteInfo? redirect(SessionState state) => sessionRedirect(state);
}

class GuestGuard extends _SessionAwareGuard {
  GuestGuard(super.session);

  @override
  PageRouteInfo? redirect(SessionState state) => guestRedirect(state);
}

class EmailConfirmGuard extends _SessionAwareGuard {
  EmailConfirmGuard(super.session);

  @override
  PageRouteInfo? redirect(SessionState state) => emailConfirmRedirect(state);
}
