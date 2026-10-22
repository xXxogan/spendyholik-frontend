import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/logger/talker_auto_route_observer.dart';
import 'package:talker/talker.dart';

class MockRouteMatch extends Mock implements RouteMatch {}

Route<void> route(String name) =>
    PageRouteBuilder<void>(settings: RouteSettings(name: name), pageBuilder: (_, _, _) => const SizedBox());

TabPageRoute tab(String name, int index) {
  final match = MockRouteMatch();
  when(() => match.name).thenReturn(name);
  return TabPageRoute(routeInfo: match, index: index);
}

void main() {
  late Talker talker;
  late TalkerAutoRouteObserver observer;

  setUp(() {
    talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    observer = TalkerAutoRouteObserver(talker);
  });

  String lastMessage() => talker.history.last.message!;

  test('push и pop вложенных и корневых страниц', () {
    observer.didPush(route('AccountsRoute'), route('TabsRoute'));
    expect(lastMessage(), contains('AccountsRoute'));
    expect(talker.history.last.key, TalkerKey.route);

    observer.didPop(route('AccountsRoute'), route('TabsRoute'));
    expect(lastMessage(), allOf(contains('AccountsRoute'), contains('TabsRoute')));
  });

  test('replace (replaceAll после обновления страницы) пишет обе страницы', () {
    observer.didReplace(newRoute: route('TabsRoute'), oldRoute: route('AccountsRoute'));

    expect(lastMessage(), allOf(contains('TabsRoute'), contains('AccountsRoute')));
  });

  test('первое открытие и переключение вкладок', () {
    observer.didInitTabRoute(tab('AnalyticsRoute', 2), tab('DashboardRoute', 0));
    expect(lastMessage(), allOf(contains('AnalyticsRoute'), contains('DashboardRoute')));

    observer.didChangeTabRoute(tab('DashboardRoute', 0), tab('AnalyticsRoute', 2));
    expect(lastMessage(), allOf(contains('DashboardRoute'), contains('AnalyticsRoute')));
    expect(talker.history, hasLength(2));
  });
}
