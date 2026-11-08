import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/network/auth_tokens.dart';
import 'package:spendyholik/core/network/token_storage.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Пара токенов — одна запись под одним ключом, все операции по очереди:
/// на Web параллельные вызовы на пустом хранилище создают два ключа шифрования,
/// и одно из значений больше не читается (flutter_secure_storage #1289, спайк S-02).
@LazySingleton(as: TokenStorage)
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._secure);

  static const _key = 'auth.tokens';

  final FlutterSecureStorage _secure;
  Future<void> _tail = Future.value();

  @override
  Future<AuthTokens?> read() => _queued(() async {
    try {
      final raw = await _secure.read(key: _key);
      if (raw == null) return null;
      return AuthTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object catch (error, stackTrace) {
      // На Web ошибка расшифровки — JS OperationError, а не Exception.
      getIt<Talker>().handle(error, stackTrace, 'Token read failed');
      await _secure.delete(key: _key);
      return null;
    }
  });

  @override
  Future<void> write(AuthTokens tokens) => _queued(
    () => _secure.write(key: _key, value: jsonEncode(tokens.toJson())),
  );

  @override
  Future<void> clear() => _queued(() => _secure.delete(key: _key));

  Future<T> _queued<T>(Future<T> Function() body) {
    final result = _tail.then((_) => body());
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }
}
