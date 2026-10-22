import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:spendyholik/core/logger/liquid_glass_log.dart';
import 'package:talker/talker.dart';

@lazySingleton
class LiquidGlassTalkerLogger {
  LiquidGlassTalkerLogger(this._talker);

  final Talker _talker;

  // Префиксы debugPrint из исходников liquid_glass_widgets 1.14.0.
  static const _printPrefixes = [
    '[LiquidGlass]',
    '[GlassModalSheet]',
    '[GlassEffect]',
    '[LightweightGlass]',
    'GlassAdaptiveScope:',
    'GlassContainer:',
  ];
  static const _errorLibrary = 'liquid_glass_widgets';

  /// Перехватывает `debugPrint` и `FlutterError.onError`: у пакета нет своего
  /// логгера, он пишет только туда. Возвращает функцию, снимающую перехват.
  VoidCallback attach() {
    final previousPrint = debugPrint;
    final previousOnError = FlutterError.onError;

    debugPrint = (message, {wrapWidth}) {
      if (message != null && _printPrefixes.any(message.startsWith)) {
        _talker.logCustom(LiquidGlassLog(message, logLevel: _levelOf(message)));
      } else {
        previousPrint(message, wrapWidth: wrapWidth);
      }
    };

    // Предупреждение о бюджете кадра пакет отдаёт через FlutterError.reportError.
    FlutterError.onError = (details) {
      if (details.library == _errorLibrary) {
        _talker.logCustom(
          LiquidGlassLog(details.toString(), logLevel: LogLevel.warning),
        );
      } else {
        previousOnError?.call(details);
      }
    };

    return () {
      debugPrint = previousPrint;
      FlutterError.onError = previousOnError;
    };
  }

  GlassAdaptiveScopeConfig adaptiveConfig() => GlassAdaptiveScopeConfig(
    onDiagnostic: (diagnostic) =>
        _talker.logCustom(LiquidGlassLog(diagnostic.toString())),
  );

  LogLevel _levelOf(String message) =>
      message.contains('WARNING') ? LogLevel.warning : LogLevel.debug;
}
