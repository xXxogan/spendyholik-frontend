import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:spendyholik/core/logger/app_route_log.dart';
import 'package:talker/talker.dart';

/// TalkerRouteObserver из talker_flutter видит только push/pop: переключение
/// вкладок auto_route шлёт через колбэки AutoRouterObserver, а replaceAll — через
/// didReplace/didRemove. Экземпляр нужен на каждый навигатор — вложенные роутеры
/// получают его из билдера `config(navigatorObservers:)`.
class TalkerAutoRouteObserver extends AutoRouterObserver {
  TalkerAutoRouteObserver(this._talker);

  final Talker _talker;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log('Open ${_name(route)}${_from(previousRoute)}');

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _log(
    'Close ${_name(route)}${previousRoute == null ? '' : ' → ${_name(previousRoute)}'}',
  );

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _log('Replace ${_name(oldRoute)} → ${_name(newRoute)}');

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log('Remove ${_name(route)}');

  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) => _log(
    'Open tab ${route.name}${previousRoute == null ? '' : ' (from ${previousRoute.name})'}',
  );

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) =>
      _log('Switch tab ${previousRoute.name} → ${route.name}');

  void _log(String message) => _talker.logCustom(AppRouteLog(message));

  String _from(Route<dynamic>? previous) =>
      previous == null ? '' : ' (from ${_name(previous)})';

  String _name(Route<dynamic>? route) =>
      route?.settings.name ?? route?.runtimeType.toString() ?? '—';
}
