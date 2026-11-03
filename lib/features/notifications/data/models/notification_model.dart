enum NotificationKind {
  budgetAlmostSpent,
  incomeReceived,
  recurringTomorrow,
  goalProgress,
}

/// Текст собирается в UI из ARB по [kind] и полям — сервер готовых строк
/// не присылает.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.isRead,
    required this.subject,
    this.amount,
    this.percent,
  });

  final String id;
  final NotificationKind kind;
  final DateTime createdAt;
  final bool isRead;

  /// Имя бюджета, источника дохода, шаблона или цели.
  final String subject;
  final int? amount;

  /// Для бюджета и цели.
  final int? percent;

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id,
    kind: kind,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
    subject: subject,
    amount: amount,
    percent: percent,
  );
}
