import 'package:auto_route/auto_route.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomeRoute.page,
      path: "/",
      initial: true,
      children: [
        AutoRoute(page: GeneralRoute.page, path: "general"),
        AutoRoute(page: TransactionsRoute.page, path: "transactions"),
        AutoRoute(page: AnalyticsRoute.page, path: "analytics"),
        AutoRoute(page: BudgetRoute.page, path: "budget"),
        AutoRoute(page: ProfileRoute.page, path: "profile"),
      ],
    ),
  ];
}
