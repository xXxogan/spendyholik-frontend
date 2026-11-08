import 'package:json_annotation/json_annotation.dart';

part 'api_error_dto.g.dart';

/// Единый формат ошибок API: `{code, detail, errors: {поле: код}}`.
@JsonSerializable(createToJson: false)
class ApiErrorDto {
  const ApiErrorDto({
    required this.code,
    required this.detail,
    this.errors = const {},
  });

  factory ApiErrorDto.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorDtoFromJson(json);

  final String code;
  final String detail;
  final Map<String, String> errors;
}
