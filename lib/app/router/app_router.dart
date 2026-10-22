import 'package:auto_route/auto_route.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';

@lazySingleton
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomeRoute.page,
      path: '/',
      initial: true,
      children: [
        AutoRoute(
          page: TabsRoute.page,
          path: '',
          initial: true,
          children: [
            AutoRoute(
              page: DashboardRoute.page,
              path: 'dashboard',
              initial: true,
            ),
            AutoRoute(page: TransactionsRoute.page, path: 'transactions'),
            AutoRoute(page: AnalyticsRoute.page, path: 'analytics'),
            AutoRoute(page: BudgetsRoute.page, path: 'budgets'),
            AutoRoute(page: ProfileRoute.page, path: 'profile'),
          ],
        ),
        AutoRoute(page: AccountsRoute.page, path: 'accounts'),
        AutoRoute(page: AccountCreateRoute.page, path: 'accounts/new'),
        AutoRoute(page: AccountDetailRoute.page, path: 'accounts/:accountId'),
        AutoRoute(
          page: AccountEditRoute.page,
          path: 'accounts/:accountId/edit',
        ),
        AutoRoute(page: CategoriesRoute.page, path: 'categories'),
      ],
    ),
  ];
}
