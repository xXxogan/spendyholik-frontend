import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/network/api_call.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/settings/data/api/notification_preferences_api.dart';
import 'package:spendyholik/features/settings/data/models/models.dart';
import 'package:spendyholik/features/settings/data/models/notification_preferences_dtos.dart';
import 'package:spendyholik/features/settings/data/repositories/notification_preferences_repository.dart';

@LazySingleton(as: NotificationPreferencesRepository)
class RemoteNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  RemoteNotificationPreferencesRepository(this._api, this._reader, this._cache);

  /// Свой ключ, не `profile`: в кэш профиля фича user пишет свою форму без
  /// `notify_*` и затёрла бы переключатели, а наша форма — без полей профиля.
  static final _key = cacheKey('profile/notifications');

  final NotificationPreferencesApi _api;
  final CachedReader _reader;
  final ApiCache _cache;

  @override
  Future<NotificationPreferences> load() async => _model(
    await _reader.read(
      key: _key,
      fetch: () => callApi(_api.get),
      toJson: (dto) => dto.toJson(),
      fromJson: (json) =>
          NotificationPreferencesDto.fromJson(json! as Map<String, dynamic>),
    ),
  );

  @override
  Future<NotificationPreferences> save(
    NotificationPreferences preferences,
  ) async {
    final dto = await callApi(
      () => _api.update(
        NotificationPreferencesDto(
          notifyBudget: preferences.budget,
          notifyGoal: preferences.goal,
          notifyRecurring: preferences.recurring,
          notifyIncome: preferences.income,
        ),
      ),
    );
    await _cache.write(_key, jsonEncode(dto.toJson()));
    return _model(dto);
  }

  static NotificationPreferences _model(NotificationPreferencesDto dto) =>
      NotificationPreferences(
        budget: dto.notifyBudget,
        goal: dto.notifyGoal,
        recurring: dto.notifyRecurring,
        income: dto.notifyIncome,
      );
}
