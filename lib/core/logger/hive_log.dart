import 'package:talker/talker.dart';

class HiveLog extends TalkerLog {
  HiveLog(String super.message, {super.logLevel})
    : super(key: logKey, title: logKey);

  static const logKey = 'hive';
}
