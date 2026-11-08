import 'package:json_annotation/json_annotation.dart';

part 'auth_tokens.g.dart';

@JsonSerializable()
class AuthTokens {
  const AuthTokens({
    required this.access,
    required this.refresh,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);

  final String access;
  final String refresh;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;

  Map<String, dynamic> toJson() => _$AuthTokensToJson(this);
}
