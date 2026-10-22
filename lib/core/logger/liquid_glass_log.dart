import 'package:talker/talker.dart';

class LiquidGlassLog extends TalkerLog {
  LiquidGlassLog(String super.message, {super.logLevel})
    : super(key: logKey, title: logKey);

  static const logKey = 'liquid_glass';
}
