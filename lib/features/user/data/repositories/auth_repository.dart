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

  /// [currentPassword] — при смене email (иначе `ValidationFailure(
  /// 'currentPassword', required)`); после смены новый адрес не подтверждён.
  Future<UserModel> updateProfile({
    required String name,
    required String email,
    String? currentPassword,
  });

  Future<UserModel> setBaseCurrency(Currency currency);

  /// Код для смены пароля уходит на почту; [RateLimitedFailure] — слишком часто.
  Future<void> requestPasswordChangeCode();

  /// Новый пароль по коду из письма; `ValidationFailure('code', …)` при ошибке
  /// кода. Сервер отзывает все сессии — репозиторий сразу входит заново.
  Future<void> changePassword(String code, String next);

  /// Код для сброса пароля уходит на [email] (без входа); ответ не говорит,
  /// есть ли адрес. [RateLimitedFailure] — слишком часто.
  Future<void> requestPasswordReset(String email);

  /// Новый пароль по коду; `ValidationFailure('code', …)` при ошибке кода.
  /// Сервер отзывает все сессии, пользователь не входит.
  Future<void> confirmPasswordReset(String email, String code, String next);
}
