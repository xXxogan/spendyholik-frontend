import 'package:json_annotation/json_annotation.dart';

part 'auth_dtos.g.dart';

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class AuthOutDto {
  const AuthOutDto({
    required this.access,
    required this.refresh,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
  });

  factory AuthOutDto.fromJson(Map<String, dynamic> json) =>
      _$AuthOutDtoFromJson(json);

  final String access;
  final String refresh;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;
}

/// `theme`, `onboarded` не читаются: настройки локальные (решение 2026-11-07).
/// toJson — для кэша: без сети профиль берётся из последнего ответа.
@JsonSerializable(fieldRename: FieldRename.snake)
class ProfileOutDto {
  const ProfileOutDto({
    required this.userId,
    required this.firstName,
    required this.email,
    this.emailVerified = true,
    this.baseCurrency,
  });

  factory ProfileOutDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileOutDtoFromJson(json);

  final String userId;
  final String firstName;
  final String email;

  /// По умолчанию true: в кэше профиля до круга 3 поля нет, а старые
  /// пользователи подтверждены миграцией сервера.
  @JsonKey(defaultValue: true)
  final bool emailVerified;
  final String? baseCurrency;

  Map<String, dynamic> toJson() => _$ProfileOutDtoToJson(this);
}

@JsonSerializable(createFactory: false)
class LoginBody {
  const LoginBody({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => _$LoginBodyToJson(this);
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class RegisterBody {
  const RegisterBody({
    required this.email,
    required this.password,
    required this.firstName,
    required this.personalDataConsent,
  });

  final String email;
  final String password;
  final String firstName;

  /// Согласие на обработку ПДн (152-ФЗ): без true сервер не регистрирует.
  final bool personalDataConsent;

  Map<String, dynamic> toJson() => _$RegisterBodyToJson(this);
}

@JsonSerializable(createFactory: false)
class ConfirmEmailBody {
  const ConfirmEmailBody({required this.code});

  final String code;

  Map<String, dynamic> toJson() => _$ConfirmEmailBodyToJson(this);
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class RefreshBody {
  const RefreshBody({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() => _$RefreshBodyToJson(this);
}

@JsonSerializable(
  createFactory: false,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
)
class ProfilePatchBody {
  const ProfilePatchBody({
    this.firstName,
    this.email,
    this.currentPassword,
    this.baseCurrency,
  });

  final String? firstName;
  final String? email;

  /// Сервер спрашивает его только при смене email.
  final String? currentPassword;
  final String? baseCurrency;

  Map<String, dynamic> toJson() => _$ProfilePatchBodyToJson(this);
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
/// Старого пароля сервер больше не спрашивает: смену подтверждает код из письма.
class PasswordBody {
  const PasswordBody({required this.code, required this.newPassword});

  final String code;
  final String newPassword;

  Map<String, dynamic> toJson() => _$PasswordBodyToJson(this);
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class RequestPasswordResetBody {
  const RequestPasswordResetBody({required this.email});

  final String email;

  Map<String, dynamic> toJson() => _$RequestPasswordResetBodyToJson(this);
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class ConfirmPasswordResetBody {
  const ConfirmPasswordResetBody({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  final String email;
  final String code;
  final String newPassword;

  Map<String, dynamic> toJson() => _$ConfirmPasswordResetBodyToJson(this);
}
