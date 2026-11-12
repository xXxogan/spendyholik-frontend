import 'package:json_annotation/json_annotation.dart';

part 'notification_preferences_dtos.g.dart';

/// Только `notify_*` из `ProfileOut`: остальной профиль читает фича user.
/// `notify_weekly_report` не читаем — отчёта в приложении нет.
@JsonSerializable(fieldRename: FieldRename.snake)
class NotificationPreferencesDto {
  const NotificationPreferencesDto({
    required this.notifyBudget,
    required this.notifyGoal,
    required this.notifyRecurring,
    required this.notifyIncome,
  });

  factory NotificationPreferencesDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesDtoFromJson(json);

  final bool notifyBudget;
  final bool notifyGoal;
  final bool notifyRecurring;
  final bool notifyIncome;

  /// И тело PATCH, и запись в кэш.
  Map<String, dynamic> toJson() => _$NotificationPreferencesDtoToJson(this);
}
