import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Для всех Cubit проекта: ошибки — в Talker, emit после close — пропуск.
mixin CubitLogging<State> on Cubit<State> {
  /// Загрузка, начатая по шине изменений, может закончиться, когда страница
  /// уже ушла и закрыла Cubit; bloc на такой emit бросает StateError.
  @override
  void emit(State state) {
    if (isClosed) return;
    super.emit(state);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    getIt<Talker>().handle(error, stackTrace);
  }
}
