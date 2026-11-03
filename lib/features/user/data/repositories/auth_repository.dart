import 'package:spendyholik/core/models/currency.dart';
import 'package:spendyholik/features/user/data/models/models.dart';

/// Все методы бросают только [Failure] из `core/errors`.
abstract interface class AuthRepository {
  /// Текущий пользователь после любого изменения; null — вышел.
  Stream<UserModel?> get userChanges;

  Future<UserModel?> restoreSession();

  /// [InvalidCredentialsFailure] при неверной паре.
  Future<UserModel> signIn(String email, String password);

  /// Фаза 1: входит под фейкового пользователя.
  Future<UserModel> signInWith(AuthProvider provider);

  /// [EmailTakenFailure], если email занят.
  Future<UserModel> register(String name, String email, String password);

  Future<void> signOut();

  Future<UserModel> updateProfile({
    required String name,
    required String email,
  });

  Future<UserModel> setBaseCurrency(Currency currency);

  /// `ValidationFailure('currentPassword', wrongPassword)` при неверном текущем.
  Future<void> changePassword(String current, String next);
}
