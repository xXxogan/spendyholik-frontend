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

  @override
  Future<UserModel> signIn(String email, String password) => _signInAs(() {
    final match = _backend.accountsOfUsers.where(
      (a) => _sameEmail(a.$1.email, email) && a.$2 == password,
    );
    if (match.isEmpty) throw const InvalidCredentialsFailure();
    return match.first.$1;
  });

  @override
  Future<UserModel> register(String name, String email, String password) =>
      _signInAs(() {
        if (_backend.accountsOfUsers.any(
          (a) => _sameEmail(a.$1.email, email),
        )) {
          throw const EmailTakenFailure();
        }
        final user = UserModel(
          id: 'user-${DateTime.now().microsecondsSinceEpoch}',
          name: name,
          email: email,
        );
        _backend.accountsOfUsers.add((user, password));
        return user;
      });

  // Профиль — T-30.
  @override
  Future<UserModel> updateProfile({
    required String name,
    required String email,
  }) => throw UnimplementedError();

  @override
  Future<void> changePassword(String current, String next) =>
      throw UnimplementedError();

  Future<UserModel> _signInAs(UserModel Function() resolve) async {
    final user = await _backend(() => _backend.user = resolve());
    _changes.add(user);
    return user;
  }

  bool _sameEmail(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();
}
