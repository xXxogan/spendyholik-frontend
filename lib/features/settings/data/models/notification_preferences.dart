import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences.freezed.dart';

/// Какие уведомления создаёт сервер; push — отдельно, в [AppSettings].
enum NotificationPreference { budget, goal, recurring, income }

@freezed
abstract class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    required bool budget,
    required bool goal,
    required bool recurring,
    required bool income,
  }) = _NotificationPreferences;

  const NotificationPreferences._();

  bool of(NotificationPreference kind) => switch (kind) {
    .budget => budget,
    .goal => goal,
    .recurring => recurring,
    .income => income,
  };

  NotificationPreferences withValue(NotificationPreference kind, bool value) =>
      switch (kind) {
        .budget => copyWith(budget: value),
        .goal => copyWith(goal: value),
        .recurring => copyWith(recurring: value),
        .income => copyWith(income: value),
      };
}
