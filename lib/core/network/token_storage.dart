import 'package:spendyholik/core/network/auth_tokens.dart';

abstract interface class TokenStorage {
  /// null — токенов нет или их не прочитать: такое считается отсутствием сессии.
  Future<AuthTokens?> read();

  Future<void> write(AuthTokens tokens);

  Future<void> clear();
}
