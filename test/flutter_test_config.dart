import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Cubit пишут ошибки в `getIt<Talker>()` — тестам нужен тихий Talker.
/// Регистрация перед каждым тестом: часть тестов делает getIt.reset().
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    if (!getIt.isRegistered<Talker>()) {
      getIt.registerSingleton(
        Talker(settings: TalkerSettings(useConsoleLogs: false)),
      );
    }
  });
  await testMain();
}
