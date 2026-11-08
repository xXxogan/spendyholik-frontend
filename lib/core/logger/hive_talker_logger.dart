import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/logger/hive_log.dart';
import 'package:talker/talker.dart';

/// У hive_ce нет хука логов: его `Logger` (не экспортирован) пишет голым
/// `print`, поэтому сообщения узнаются по тексту из исходников hive_ce 2.23.1.
@lazySingleton
class HiveTalkerLogger {
  HiveTalkerLogger(this._talker);

  final Talker _talker;

  static final _messages = <(RegExp, LogLevel)>[
    (RegExp(r'^Creating objectStore .+ in database '), .info),
    (RegExp(r'^Got object store .+ in database '), .info),
    (RegExp(r'^Restoring compacted file\.'), .info),
    (RegExp(r'^Recovering corrupted box\.'), .info),
    (RegExp(r'^Delete .+ // .+ from disk$'), .debug),
    (RegExp(r'^You are trying to override .+ for typeId'), .debug),
    (RegExp(r'^Removed existing adapter '), .debug),
    (RegExp(r'^Registering type adapters for dynamic type'), .warning),
    (
      RegExp(r'^WARNING: (You are trying to register|Writing integer|CRC)'),
      .warning,
    ),
    (RegExp(r'^⚠️ WARNING: HIVE MULTI-ISOLATE'), .warning),
  ];

  var _logging = false;

  /// Обработчик `print` зоны приложения. [forward] — печать в консоль как
  /// обычно: для чужих строк и для вывода самого Talker, который тоже идёт
  /// через `print` этой зоны.
  void handlePrint(String line, void Function() forward) {
    if (_logging) return forward();
    final level = _levelOf(line);
    if (level == null) return forward();
    _logging = true;
    try {
      _talker.logCustom(HiveLog(line, logLevel: level));
    } finally {
      _logging = false;
    }
  }

  LogLevel? _levelOf(String line) {
    for (final (pattern, level) in _messages) {
      if (pattern.hasMatch(line)) return level;
    }
    return null;
  }
}
