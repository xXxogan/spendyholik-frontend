import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/utils/glass_quality_adapter.dart' show AdaptivePhase;
import 'package:spendyholik/core/logger/liquid_glass_talker_logger.dart';
import 'package:talker/talker.dart';

void main() {
  late Talker talker;
  late LiquidGlassTalkerLogger logger;
  late List<String?> printed;
  late List<FlutterErrorDetails> presented;

  setUp(() {
    talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    logger = LiquidGlassTalkerLogger(talker);
    printed = [];
    presented = [];

    final originalPrint = debugPrint;
    final originalOnError = FlutterError.onError;
    debugPrint = (message, {wrapWidth}) => printed.add(message);
    FlutterError.onError = presented.add;
    final detach = logger.attach();
    addTearDown(() {
      detach();
      debugPrint = originalPrint;
      FlutterError.onError = originalOnError;
    });
  });

  test('debugPrint пакета стекла уходит в Talker, а не в консоль', () {
    debugPrint('[LiquidGlass] Initialization complete.');

    expect(printed, isEmpty);
    expect(talker.history.single, isA<LiquidGlassLog>());
    expect(talker.history.single.message, contains('Initialization complete'));
  });

  test('чужой debugPrint остаётся в консоли', () {
    debugPrint('something else');

    expect(printed, ['something else']);
    expect(talker.history, isEmpty);
  });

  test('detach возвращает прежние обработчики', () {
    final printBefore = debugPrint;
    final onErrorBefore = FlutterError.onError;

    LiquidGlassTalkerLogger(talker).attach()();

    expect(debugPrint, same(printBefore));
    expect(FlutterError.onError, same(onErrorBefore));
  });

  test('диагностика адаптивного качества пишется в Talker', () {
    logger.adaptiveConfig().onDiagnostic!(
      const GlassAdaptiveDiagnostic(
        from: GlassQuality.standard,
        to: GlassQuality.minimal,
        reason: GlassQualityChangeReason.thermalDegradation,
        phase: AdaptivePhase.runtime,
        p95Ms: 31.5,
      ),
    );

    final log = talker.history.single;
    expect(log, isA<LiquidGlassLog>());
    expect(log.message, allOf(contains('standard'), contains('minimal')));
  });

  test('предупреждение пакета через FlutterError — в Talker как warning', () {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: Exception('budget exceeded'),
        library: 'liquid_glass_widgets',
      ),
    );

    expect(presented, isEmpty);
    expect(talker.history.single.logLevel, LogLevel.warning);
  });

  test('чужие ошибки Flutter идут прежнему обработчику', () {
    FlutterError.reportError(FlutterErrorDetails(exception: Exception('other')));

    expect(presented, hasLength(1));
    expect(talker.history, isEmpty);
  });
}
