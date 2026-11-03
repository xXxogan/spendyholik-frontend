import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/notifications/data/models/models.dart';
import 'package:spendyholik/features/notifications/data/repositories/notification_repository.dart';

@LazySingleton(as: NotificationRepository)
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository(this._backend, this._bus);

  final FakeBackend _backend;
  final DataChangeBus _bus;

  @override
  Future<List<NotificationModel>> getNotifications() => _backend(
    () =>
        _backend.notifications.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );

  @override
  Future<int> getUnreadCount() =>
      _backend(() => _backend.notifications.where((n) => !n.isRead).length);

  @override
  Future<void> markRead(String id) async {
    await _backend(() => _backend.markNotificationRead(id));
    _bus.emit({DataTopic.notifications});
  }
}
