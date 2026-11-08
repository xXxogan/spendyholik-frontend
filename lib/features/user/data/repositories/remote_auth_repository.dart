import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/currency.dart';
import 'package:spendyholik/core/network/auth_tokens.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/failure_mapper.dart';
import 'package:spendyholik/core/network/session_expiry.dart';
import 'package:spendyholik/core/network/token_storage.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/user/data/api/auth_api.dart';
import 'package:spendyholik/features/user/data/models/auth_dtos.dart';
import 'package:spendyholik/features/user/data/models/models.dart';
import 'package:spendyholik/features/user/data/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(
    this._api,
    this._tokens,
    SessionExpiry expiry,
    this._reader,
    this._cache,
  ) {
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
  };

  final AuthApi _api;
  final TokenStorage _tokens;
  final CachedReader _reader;
  final ApiCache _cache;
  final _changes = StreamController<UserModel?>.broadcast();

  @override
  Stream<UserModel?> get userChanges => _changes.stream;

  @override
  Future<UserModel?> restoreSession() async {
    if (await _tokens.read() == null) return null;
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
  Future<UserModel> register(String name, String email, String password) =>
      _signInWith(
        () => _api.register(
          RegisterBody(email: email, password: password, firstName: name),
        ),
      );

  /// Сессия на сервере гасится по возможности: локально выходим в любом случае.
  @override
  Future<void> signOut() async {
    final tokens = await _tokens.read();
    if (tokens != null) {
      try {
        await _api.logout(RefreshBody(refreshToken: tokens.refresh));
      } on DioException {
        // Без сети refresh доживёт до своего срока на сервере — это допустимо.
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
  Future<UserModel> setBaseCurrency(Currency currency) =>
      _patch(ProfilePatchBody(baseCurrency: currency.code));

  @override
  Future<void> changePassword(String current, String next) => _call(
    () => _api.changePassword(
      PasswordBody(oldPassword: current, newPassword: next),
    ),
  );

  Future<UserModel> _signInWith(Future<AuthOutDto> Function() request) async {
    final auth = await _call(request);
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

  Future<ProfileOutDto> _profile() => _reader.read(
    key: _profileKey,
    fetch: () => _call(_api.profile),
    toJson: (dto) => dto.toJson(),
    fromJson: (json) => ProfileOutDto.fromJson(json! as Map<String, dynamic>),
  );

  UserModel _user(ProfileOutDto dto) => UserModel(
    id: dto.userId,
    name: dto.firstName,
    email: dto.email,
    baseCurrency: Currency.fromCode(dto.baseCurrency),
  );

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw mapDioException(e, fields: _fields);
    }
  }
}
