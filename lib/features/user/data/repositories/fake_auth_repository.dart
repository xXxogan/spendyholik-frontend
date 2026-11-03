import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/models/currency.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/user/data/models/models.dart';
import 'package:spendyholik/features/user/data/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._backend);

  final FakeBackend _backend;
  final _changes = StreamController<UserModel?>.broadcast();

  @override
  Stream<UserModel?> get userChanges => _changes.stream;

  @override
  Future<UserModel?> restoreSession() => _backend(() => _backend.user);

  @override
  Future<void> signOut() async {
    await _backend(() => _backend.user = null);
    _changes.add(null);
  }

  @override
  Future<UserModel> setBaseCurrency(Currency currency) async {
    final user = await _backend(() {
      final current = _backend.user ?? (throw const UnauthorizedFailure());
      return _backend.user = current.copyWith(baseCurrency: currency);
    });
    _changes.add(user);
    return user;
  }

  // Вход и регистрация — T-29, профиль — T-30.
  @override
  Future<UserModel> signIn(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<UserModel> signInWith(AuthProvider provider) =>
      throw UnimplementedError();

  @override
  Future<UserModel> register(String name, String email, String password) =>
      throw UnimplementedError();

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String email,
  }) => throw UnimplementedError();

  @override
  Future<void> changePassword(String current, String next) =>
      throw UnimplementedError();
}
