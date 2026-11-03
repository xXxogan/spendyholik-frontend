import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/notifications/data/models/models.dart';
import 'package:spendyholik/features/notifications/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'notifications_cubit.freezed.dart';
part 'notifications_state.dart';

@injectable
class NotificationsCubit extends Cubit<NotificationsState>
    with CubitLogging<NotificationsState> {
  NotificationsCubit(this._repository, DataChangeBus bus)
    : super(const NotificationsState.loading()) {
    _changes = bus.changes
        .where((topics) => topics.contains(DataTopic.notifications))
        .listen((_) => load());
  }

  final NotificationRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;

  Future<void> load() async {
    if (state is! NotificationsLoaded) emit(const NotificationsState.loading());
    try {
      final notifications = await _repository.getNotifications();
      emit(
        notifications.isEmpty
            ? const NotificationsState.empty()
            : NotificationsState.loaded(notifications),
      );
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(NotificationsState.error(failure));
    }
  }

  /// Пометка видна сразу, не дожидаясь сервера; не удалось — откат.
  Future<void> markRead(String id) async {
    final before = switch (state) {
      NotificationsLoaded(:final notifications) => notifications,
      _ => null,
    };
    if (before == null || !before.any((n) => n.id == id && !n.isRead)) return;
    emit(
      NotificationsState.loaded([
        for (final n in before) n.id == id ? n.copyWith(isRead: true) : n,
      ]),
    );
    try {
      await _repository.markRead(id);
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(NotificationsState.loaded(before));
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
