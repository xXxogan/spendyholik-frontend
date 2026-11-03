import 'package:spendyholik/features/notifications/data/models/models.dart';

/// Все методы бросают только [Failure] из `core/errors`.
abstract interface class NotificationRepository {
  /// Новые первыми.
  Future<List<NotificationModel>> getNotifications();

  Future<int> getUnreadCount();

  Future<void> markRead(String id);
}
