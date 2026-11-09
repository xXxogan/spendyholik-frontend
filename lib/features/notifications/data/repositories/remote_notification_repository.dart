import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/network/failure_mapper.dart';
import 'package:spendyholik/features/notifications/data/api/notifications_api.dart';
import 'package:spendyholik/features/notifications/data/models/models.dart';
import 'package:spendyholik/features/notifications/data/models/notification_dtos.dart';
import 'package:spendyholik/features/notifications/data/repositories/notification_repository.dart';
import 'package:talker/talker.dart';

@LazySingleton(as: NotificationRepository)
class RemoteNotificationRepository implements NotificationRepository {
  RemoteNotificationRepository(
    this._api,
    this._reader,
    this._bus,
    this._talker,
  );

  static const _kinds = {
    'budget_almost_spent': NotificationKind.budgetAlmostSpent,
    'income_received': NotificationKind.incomeReceived,
    'recurring_tomorrow': NotificationKind.recurringTomorrow,
    'goal_progress': NotificationKind.goalProgress,
  };

  final NotificationsApi _api;
  final CachedReader _reader;
  final DataChangeBus _bus;
  final Talker _talker;

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final dtos = await _reader.read(
      key: cacheKey('notifications'),
      fetch: () => _call(_api.list),
      toJson: (list) => [for (final dto in list) dto.toJson()],
      fromJson: (json) => [
        for (final item in json! as List)
          NotificationOutDto.fromJson(item as Map<String, dynamic>),
      ],
    );
    return [for (final dto in dtos) ?_notification(dto)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Счётчика на сервере нет — считаем по тому же списку и кэшу.
  @override
  Future<int> getUnreadCount() async =>
      (await getNotifications()).where((n) => !n.isRead).length;

  @override
  Future<void> markRead(String id) async {
    await _call(() => _api.markRead(id));
    _bus.emit({DataTopic.notifications});
  }

  /// Без известного типа показать нечего: текст собирается из ARB по kind.
  NotificationModel? _notification(NotificationOutDto dto) {
    final kind = _kinds[dto.type];
    if (kind == null) {
      _talker.warning('Unknown notification type ${dto.type}, skipped');
      return null;
    }
    return NotificationModel(
      id: dto.id,
      kind: kind,
      // Без даты — в конец списка, а не наверх (как в долгах).
      createdAt: switch (dto.createdAt) {
        final at? => DateTime.parse(at),
        null => DateTime.fromMillisecondsSinceEpoch(0),
      },
      isRead: dto.isRead,
      subject: dto.subject,
      amount: dto.amountMinor,
      percent: dto.percent,
    );
  }

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
