import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/models/currency.dart';
import 'package:spendyholik/core/network/api_call.dart';
import 'package:spendyholik/core/network/auth_tokens.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/email_verification_required.dart';
import 'package:spendyholik/core/network/session_expiry.dart';
import 'package:spendyholik/core/network/token_storage.dart';
import 'package:spendyholik/core/session/session_currency.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/user/data/api/auth_api.dart';
import 'package:spendyholik/features/user/data/models/auth_dtos.dart';
import 'package:spendyholik/features/user/data/models/models.dart';
import 'package:spendyholik/features/user/data/repositories/auth_repository.dart';
import 'package:talker/talker.dart';

@LazySingleton(as: AuthRepository)
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(
    this._api,
    this._tokens,
    SessionExpiry expiry,
    this._reader,
    this._cache,
    this._sessionCurrency,
    this._talker,
    this._bus,
    EmailVerificationRequired verification,
  ) {
    // Почта стала неподтверждённой (сменили email) — свежий профиль уведёт
    // сессию на экран кода.
    verification.required.listen((_) => _refreshUser());
    // Токены уже стёрты интерсептором — остаётся вывести на вход.
    expiry.expired.listen((_) async {
      await _cache.clear();
      _changes.add(null);
    });
  }

  static final _profileKey = cacheKey('profile');

  static const _fields = {
    'first_name': 'name',
    'old_password': 'currentPassword',
    'new_password': 'newPassword',
    'personal_data_consent': 'consent',
    'code': 'code',
  };

  final AuthApi _api;
  final TokenStorage _tokens;
  final CachedReader _reader;
  final ApiCache _cache;
  final SessionCurrency _sessionCurrency;
  final Talker _talker;
  final DataChangeBus _bus;

  /// Email текущего пользователя — для нового входа после смены пароля.
  String? _email;
  final _changes = StreamController<UserModel?>.broadcast();

  @override
  Stream<UserModel?> get userChanges => _changes.stream;

  @override
  Future<UserModel?> restoreSession() async {
    if (await _tokens.read() == null) {
      // Токены не прочитались (Web OperationError, S-02) — кэш принадлежит
      // сессии, которой больше нет.
      await _cache.clear();
      return null;
    }
    try {
      return _user(await _profile());
    } on UnauthorizedFailure {
      await _tokens.clear();
      return null;
    }
  }

  @override
  Future<UserModel> signIn(String email, String password) => _signInWith(
    () => _api.login(LoginBody(email: email, password: password)),
  );

  @override
  Future<UserModel> register(
    String name,
    String email,
    String password, {
    required bool personalDataConsent,
  }) => _signInWith(
    () => _api.register(
      RegisterBody(
        email: email,
        password: password,
        firstName: name,
        personalDataConsent: personalDataConsent,
      ),
    ),
  );

  @override
  Future<UserModel> confirmEmail(String code) async {
    await _call(() => _api.confirmEmail(ConfirmEmailBody(code: code)));
    final user = _user(await _profile());
    _changes.add(user);
    return user;
  }

  @override
  Future<void> resendEmailCode() => _call(_api.resendEmailCode);

  /// Сессия на сервере гасится по возможности: локально выходим в любом случае.
  @override
  Future<void> signOut() async {
    final tokens = await _tokens.read();
    if (tokens != null) {
      try {
        await _api.logout(RefreshBody(refreshToken: tokens.refresh));
      } on Object {
        // Без сети refresh доживёт до своего срока на сервере — это допустимо;
        // локальный выход не должен зависеть от ответа.
      }
    }
    await _tokens.clear();
    await _cache.clear();
    _changes.add(null);
  }

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String email,
  }) => _patch(ProfilePatchBody(firstName: name, email: email));

  @override
  Future<UserModel> setBaseCurrency(Currency currency) async {
    final user = await _patch(ProfilePatchBody(baseCurrency: currency.code));
    // Итоги (общий баланс, бюджеты, аналитика) сервер пересчитал в новую
    // валюту — без этого показывались бы старые числа с новым символом.
    _bus.emit({DataTopic.accounts, DataTopic.budgets, DataTopic.transactions});
    return user;
  }

  @override
  Future<void> changePassword(String current, String next) async {
    await _call(
      () => _api.changePassword(
        PasswordBody(oldPassword: current, newPassword: next),
      ),
    );
    // Сервер отзывает все сессии при смене пароля, включая эту: без нового
    // входа через 15 минут (срок access) пользователя выкинуло бы на экран входа.
    final email = _email;
    if (email == null) return;
    try {
      await _signInWith(
        () => _api.login(LoginBody(email: email, password: next)),
      );
    } on Failure catch (error, stackTrace) {
      // Пароль уже сменён — не ошибка формы; сессия просто истечёт как обычно.
      _talker.handle(
        error,
        stackTrace,
        'Re-login after password change failed',
      );
    }
  }

  Future<UserModel> _signInWith(Future<AuthOutDto> Function() request) async {
    final auth = await _call(request);
    // Новый пользователь мог войти на том же устройстве: без очистки без сети
    // показались бы чужие данные, а профиль — прежнего пользователя.
    await _cache.clear();
    await _tokens.write(
      AuthTokens(
        access: auth.access,
        refresh: auth.refresh,
        accessExpiresAt: auth.accessExpiresAt,
        refreshExpiresAt: auth.refreshExpiresAt,
      ),
    );
    // В ответе входа нет базовой валюты — она только в профиле.
    final user = _user(await _profile());
    _changes.add(user);
    return user;
  }

  Future<UserModel> _patch(ProfilePatchBody body) async {
    final dto = await _call(() => _api.updateProfile(body));
    // Иначе без сети после правки показался бы прежний профиль.
    await _cache.write(_profileKey, jsonEncode(dto.toJson()));
    final user = _user(dto);
    _changes.add(user);
    return user;
  }

  Future<void> _refreshUser() async {
    try {
      _changes.add(_user(await _profile()));
    } on Failure catch (error, stackTrace) {
      _talker.handle(error, stackTrace, 'Profile refresh after 403 failed');
    }
  }

  Future<ProfileOutDto> _profile() => _reader.read(
    key: _profileKey,
    fetch: () => _call(_api.profile),
    toJson: (dto) => dto.toJson(),
    fromJson: (json) => ProfileOutDto.fromJson(json! as Map<String, dynamic>),
  );

  /// Каждый пользователь отсюда — текущий: его валюта нужна репозиториям.
  UserModel _user(ProfileOutDto dto) {
    final user = UserModel(
      id: dto.userId,
      name: dto.firstName,
      email: dto.email,
      baseCurrency: Currency.fromCode(dto.baseCurrency),
      emailVerified: dto.emailVerified,
    );
    if (user.baseCurrency case final currency?) {
      _sessionCurrency.value = currency;
    }
    _email = user.email;
    return user;
  }

  Future<T> _call<T>(Future<T> Function() request) =>
      callApi(request, fields: _fields);
}
