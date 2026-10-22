import 'package:talker/talker.dart';

class AppRouteLog extends TalkerLog {
  AppRouteLog(String super.message)
    : super(key: TalkerKey.route, title: TalkerKey.route);

  @override
  AnsiPen get pen => AnsiPen()..xterm(135);
}
