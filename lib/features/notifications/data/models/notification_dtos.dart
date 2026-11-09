import 'package:json_annotation/json_annotation.dart';

part 'notification_dtos.g.dart';

/// `title` и `body` сервера не читаем: текст собирается из ARB по `type`.
/// toJson — для кэша чтения.
@JsonSerializable(fieldRename: FieldRename.snake)
class NotificationOutDto {
  const NotificationOutDto({
    required this.id,
    required this.type,
    required this.subject,
    required this.isRead,
    this.amountMinor,
    this.percent,
    this.createdAt,
  });

  factory NotificationOutDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationOutDtoFromJson(json);

  final String id;

  /// budget_almost_spent | income_received | recurring_tomorrow |
  /// goal_progress.
  final String type;
  final String subject;
  final int? amountMinor;
  final int? percent;
  final bool isRead;

  /// ISO date-time.
  final String? createdAt;

  Map<String, dynamic> toJson() => _$NotificationOutDtoToJson(this);
}
