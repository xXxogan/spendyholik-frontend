import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/network/network_status.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Ключ кэша: query отсортирован, чтобы один и тот же запрос
/// не давал разных ключей из-за порядка параметров.
String cacheKey(String path, [Map<String, Object?> query = const {}]) {
  final entries = query.entries.where((e) => e.value != null).toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  if (entries.isEmpty) return path;
  return '$path?${entries.map((e) => '${e.key}=${e.value}').join('&')}';
}

/// Чтение с подстраховкой кэшем: без сети отдаёт последний ответ.
@lazySingleton
class CachedReader {
  CachedReader(this._cache, this._status, this._talker);

  final ApiCache _cache;
  final NetworkStatus _status;
  final Talker _talker;

  /// [fetch] бросает уже `Failure`. Кэш подменяет только [NetworkFailure]:
  /// ошибка сервера должна дойти до экрана, а не спрятаться за старыми данными.
  Future<T> read<T>({
    required String key,
    required Future<T> Function() fetch,
    required Object? Function(T value) toJson,
    required T Function(Object? json) fromJson,
  }) async {
    final generation = _cache.generation;
    try {
      final value = await fetch();
      _status.reportOnline();
      if (_cache.generation == generation) {
        await _cache.write(key, jsonEncode(toJson(value)));
      }
      return value;
    } on NetworkFailure catch (failure) {
      _status.reportOffline();
      final raw = await _cache.read(key);
      if (raw == null) rethrow;
      try {
        return fromJson(jsonDecode(raw));
      } on Object catch (error, stackTrace) {
        // Ответ из прошлой версии приложения: формат мог смениться.
        _talker.handle(error, stackTrace, 'Cached $key is unreadable');
        throw failure;
      }
    }
  }
}
