import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/features/settings/data/models/models.dart';
import 'package:spendyholik/features/settings/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'notification_preferences_cubit.freezed.dart';
part 'notification_preferences_state.dart';

@injectable
class NotificationPreferencesCubit extends Cubit<NotificationPreferencesState>
    with CubitLogging<NotificationPreferencesState> {
  NotificationPreferencesCubit(this._repository)
    : super(const NotificationPreferencesState.loading());

  final NotificationPreferencesRepository _repository;

  Future<void> load() async {
    emit(const NotificationPreferencesState.loading());
    try {
      emit(NotificationPreferencesState.loaded(await _repository.load()));
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      emit(NotificationPreferencesState.error(failure));
    }
  }

  /// Оптимистично. Ответ сервера не применяем: пока шёл запрос, могли
  /// переключить соседний, и ответ его вернул бы обратно.
  Future<void> toggle(NotificationPreference kind, bool value) async {
    final current = state;
    if (current is! NotificationPreferencesLoaded) return;
    final next = current.preferences.withValue(kind, value);
    emit(NotificationPreferencesState.loaded(next));
    try {
      await _repository.save(next);
    } on Failure catch (failure, stackTrace) {
      getIt<Talker>().handle(failure, stackTrace);
      if (state case NotificationPreferencesLoaded(:final preferences)) {
        emit(
          NotificationPreferencesState.loaded(
            preferences.withValue(kind, !value),
            failure: failure,
          ),
        );
      }
    }
  }
}
