import 'package:json_annotation/json_annotation.dart';

part 'money_dto.g.dart';

/// Сумма из ответа API. `formatted` сервера не берём: формат — по локали приложения.
@JsonSerializable()
class MoneyDto {
  const MoneyDto({required this.minor, required this.currency});

  factory MoneyDto.fromJson(Map<String, dynamic> json) =>
      _$MoneyDtoFromJson(json);

  final int minor;
  final String currency;

  /// Для кэша ответов.
  Map<String, dynamic> toJson() => _$MoneyDtoToJson(this);
}
