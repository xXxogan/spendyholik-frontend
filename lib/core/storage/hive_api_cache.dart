import 'package:hive_ce/hive_ce.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/core/storage/cache_entry.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Кэш — подстраховка: сбой Hive пишется в лог и не ломает загрузку экрана.
@LazySingleton(as: ApiCache)
class HiveApiCache implements ApiCache {
  HiveApiCache(this._hive, this._talker);

  static const _boxName = 'api_cache';

  final HiveInterface _hive;
  final Talker _talker;
  Future<Box<CacheEntry>>? _box;

  @override
  Future<String?> read(String key) =>
      _guard('read', () async => (await _open()).get(key)?.json, orElse: null);

  @override
  Future<void> write(String key, String json) => _guard(
    'write',
    () async => (await _open()).put(key, CacheEntry(json, DateTime.now())),
    orElse: null,
  );

  @override
  Future<void> clear() =>
      _guard('clear', () async => (await _open()).clear(), orElse: null);

  Future<Box<CacheEntry>> _open() =>
      _box ??= _hive.openBox<CacheEntry>(_boxName);

  Future<T> _guard<T>(
    String operation,
    Future<T> Function() body, {
    required T orElse,
  }) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      _box = null;
      _talker.handle(error, stackTrace, 'Api cache $operation failed');
      return orElse;
    }
  }
}
