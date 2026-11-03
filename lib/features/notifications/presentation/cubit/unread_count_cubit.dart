import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/features/notifications/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Число непрочитанных для колокольчика в шапке Главной.
@injectable
class UnreadCountCubit extends Cubit<int> with CubitLogging<int> {
  UnreadCountCubit(this._repository, DataChangeBus bus) : super(0) {
    _changes = bus.changes
        .where((topics) => topics.contains(DataTopic.notifications))
        .listen((_) => load());
  }

  final NotificationRepository _repository;
  late final StreamSubscription<Set<DataTopic>> _changes;

  /// Ошибку в шапке показывать негде — счётчик остаётся прежним.
  Future<void> load() async {
    try {
      emit(await _repository.getUnreadCount());
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
