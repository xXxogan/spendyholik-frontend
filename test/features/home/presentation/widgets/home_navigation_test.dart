import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/features/home/presentation/widgets/home_navigation.dart';

class MockStackRouter extends Mock implements StackRouter {}

class MockTabsRouter extends Mock implements TabsRouter {}

void main() {
  late MockStackRouter router;

  setUpAll(() {
    registerFallbackValue(<PageRouteInfo>[]);
    registerFallbackValue(const TabsRoute());
  });

  setUp(() {
    router = MockStackRouter();
    when(() => router.replaceAll(any())).thenAnswer((_) async {});
  });

  test('вкладки в стеке — закрыть детали и переключить вкладку', () async {
    final tabs = MockTabsRouter();

    await selectHomeTab(router, tabs, 2);

    verify(() => router.popUntilRouteWithName(TabsRoute.name)).called(1);
    verify(() => tabs.setActiveIndex(2)).called(1);
    verifyNever(() => router.replaceAll(any()));
  });

  test('вкладок в стеке нет (после обновления на детали) — заменить стек вкладками', () async {
    await selectHomeTab(router, null, 2);

    final routes =
        verify(() => router.replaceAll(captureAny())).captured.single
            as List<PageRouteInfo>;
    expect(routes.single.routeName, TabsRoute.name);
    expect(
      routes.single.initialChildren!.single.routeName,
      AnalyticsRoute.name,
    );
  });

  test('ссылка панели при вкладках в стеке — закрыть детали и открыть поверх вкладок', () async {
    when(() => router.push(any())).thenAnswer((_) async => null);
    final tabs = MockTabsRouter();

    await openHomeLink(router, tabs, const CategoriesRoute());

    verify(() => router.popUntilRouteWithName(TabsRoute.name)).called(1);
    final route =
        verify(() => router.push(captureAny())).captured.single
            as PageRouteInfo;
    expect(route.routeName, CategoriesRoute.name);
  });

  test(
    'ссылка панели без вкладок в стеке — стек из вкладок и страницы',
    () async {
      await openHomeLink(router, null, const CategoriesRoute());

      final routes =
          verify(() => router.replaceAll(captureAny())).captured.single
              as List<PageRouteInfo>;
      expect(routes.map((r) => r.routeName), [
        TabsRoute.name,
        CategoriesRoute.name,
      ]);
    },
  );
}
