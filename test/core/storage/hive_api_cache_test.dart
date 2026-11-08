import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:spendyholik/core/storage/cache_entry.dart';
import 'package:spendyholik/core/storage/hive_api_cache.dart';
import 'package:talker_flutter/talker_flutter.dart';

void main() {
  late Directory dir;
  late HiveApiCache cache;

  setUpAll(() => Hive.registerAdapter(CacheEntryAdapter()));

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('api_cache');
    Hive.init(dir.path);
    cache = HiveApiCache(Hive, Talker());
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('записанное читается', () async {
    await cache.write('accounts', '[1]');
    expect(await cache.read('accounts'), '[1]');
  });

  test('нет записи — null', () async {
    expect(await cache.read('dashboard'), isNull);
  });

  test('переживает переоткрытие бокса', () async {
    await cache.write('accounts', '[1]');
    await Hive.close();
    Hive.init(dir.path);
    expect(await HiveApiCache(Hive, Talker()).read('accounts'), '[1]');
  });

  test('clear — всё стёрто', () async {
    await cache.write('accounts', '[1]');
    await cache.write('dashboard', '{}');
    await cache.clear();
    expect(await cache.read('accounts'), isNull);
    expect(await cache.read('dashboard'), isNull);
  });
}
