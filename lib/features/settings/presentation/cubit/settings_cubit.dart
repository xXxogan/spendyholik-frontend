import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:spendyholik/features/settings/data/models/models.dart';
import 'package:spendyholik/features/settings/data/repositories/repositories.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Один на приложение: тему читает корень, поэтому `load()` — до `runApp`,
/// иначе первый кадр рисуется в системной теме и мигает.
@lazySingleton
class SettingsCubit extends Cubit<AppSettings> with CubitLogging<AppSettings> {
  SettingsCubit(this._repository) : super(const AppSettings());

  final SettingsRepository _repository;

  Future<void> load() async {
    try {
      final settings = await _repository.load();
      emit(settings);
      getIt<Talker>().info('Settings loaded: theme ${settings.themeMode.name}');
    } on Exception catch (error, stackTrace) {
      getIt<Talker>().handle(error, stackTrace, 'Settings load failed');
    }
  }

  void setDarkTheme(bool dark) =>
      _update(state.copyWith(themeMode: dark ? .dark : .light));

  void setPush(bool value) => _update(state.copyWith(pushEnabled: value));

  void setBudgetReminders(bool value) =>
      _update(state.copyWith(budgetReminders: value));

  void setWeeklyReport(bool value) =>
      _update(state.copyWith(weeklyReport: value));

  /// Переключатель меняется сразу; не сохранилось — значение живёт
  /// до перезапуска, а ошибка уходит в лог.
  Future<void> _update(AppSettings settings) async {
    emit(settings);
    try {
      await _repository.save(settings);
    } on Exception catch (error, stackTrace) {
      getIt<Talker>().handle(error, stackTrace, 'Settings save failed');
    }
  }
}
