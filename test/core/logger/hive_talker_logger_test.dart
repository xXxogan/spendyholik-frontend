// Тест перехвата print: печать здесь и есть проверяемое поведение.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/core/logger/hive_log.dart';
import 'package:spendyholik/core/logger/hive_talker_logger.dart';
import 'package:talker/talker.dart';

void main() {
  late Talker talker;
  late HiveTalkerLogger logger;
  late List<String> printed;

  setUp(() {
    talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    logger = HiveTalkerLogger(talker);
    printed = [];
  });

  /// print внутри зоны с перехватом, как в main.dart.
  void inZone(void Function() body) => runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) =>
          logger.handlePrint(line, () => printed.add(line)),
    ),
  );

  test('сообщение Hive уходит в Talker, а не в консоль', () {
    inZone(() => print('Got object store box in database api_cache.'));

    expect(printed, isEmpty);
    final log = talker.history.single;
    expect(log, isA<HiveLog>());
    expect(log.message, contains('api_cache'));
    expect(log.logLevel, LogLevel.info);
  });

  test('предупреждение Hive — уровень warning', () {
    inZone(
      () => print(
        'WARNING: Writing integer values greater than 2^53 will result in '
        'precision loss.',
      ),
    );

    expect(talker.history.single.logLevel, LogLevel.warning);
  });

  test('удаление бокса — уровень debug', () {
    inZone(() => print('Delete api_cache // box from disk'));

    expect(talker.history.single.logLevel, LogLevel.debug);
  });

  test('чужой print остаётся в консоли', () {
    inZone(() => print('something else'));

    expect(printed, ['something else']);
    expect(talker.history, isEmpty);
  });
}
