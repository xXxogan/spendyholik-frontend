import 'package:spendyholik/core/models/currency.dart';
import 'package:spendyholik/features/user/data/models/models.dart';

/// Все методы бросают только [Failure] из `core/errors`.
abstract interface class AuthRepository {
  /// Текущий пользователь после любого изменения; null — вышел.
  Stream<UserModel?> get userChanges;

  Future<UserModel?> restoreSession();

  /// [InvalidCredentialsFailure] при неверной паре.
  Future<UserModel> signIn(String email, String password);

  /// [EmailTakenFailure], если email занят. Без [personalDataConsent] сервер
  /// откажет: `ValidationFailure('consent', required)`. Новый пользователь —
  /// с неподтверждённой почтой.
  Future<UserModel> register(
    String name,
    String email,
    String password, {
    required bool personalDataConsent,
  });

  /// Код из письма; `ValidationFailure('code', invalidCode | codeExpired |
  /// tooManyAttempts)` при ошибке.
  Future<UserModel> confirmEmail(String code);

  /// [RateLimitedFailure], если код запрошен раньше минуты или кончился лимит дня.
  Future<void> resendEmailCode();

  Future<void> signOut();

  Future<UserModel> updateProfile({
    required String name,
    required String email,
  });

  Future<UserModel> setBaseCurrency(Currency currency);

  /// `ValidationFailure('currentPassword', wrongPassword)` при неверном текущем.
  Future<void> changePassword(String current, String next);
}
