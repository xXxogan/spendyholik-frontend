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

/// `theme`, `onboarded`, `notify_*` не читаются: настройки локальные (решение 2026-11-07).
/// toJson — для кэша: без сети профиль берётся из последнего ответа.
@JsonSerializable(fieldRename: FieldRename.snake)
class ProfileOutDto {
  const ProfileOutDto({
    required this.userId,
    required this.firstName,
    required this.email,
    this.baseCurrency,
  });

  factory ProfileOutDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileOutDtoFromJson(json);

  final String userId;
  final String firstName;
  final String email;
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
  });

  final String email;
  final String password;
  final String firstName;

  Map<String, dynamic> toJson() => _$RegisterBodyToJson(this);
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
  const ProfilePatchBody({this.firstName, this.email, this.baseCurrency});

  final String? firstName;
  final String? email;
  final String? baseCurrency;

  Map<String, dynamic> toJson() => _$ProfilePatchBodyToJson(this);
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class PasswordBody {
  const PasswordBody({required this.oldPassword, required this.newPassword});

  final String oldPassword;
  final String newPassword;

  Map<String, dynamic> toJson() => _$PasswordBodyToJson(this);
}
