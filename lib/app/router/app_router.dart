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
        AutoRoute(page: TransactionCreateRoute.page, path: 'transactions/new'),
        AutoRoute(
          page: TransactionDetailRoute.page,
          path: 'transactions/:transactionId',
        ),
        AutoRoute(
          page: TransactionEditRoute.page,
          path: 'transactions/:transactionId/edit',
        ),
        AutoRoute(page: BudgetCreateRoute.page, path: 'budgets/new'),
        AutoRoute(page: BudgetDetailRoute.page, path: 'budgets/:budgetId'),
        AutoRoute(page: BudgetEditRoute.page, path: 'budgets/:budgetId/edit'),
        AutoRoute(page: GoalCreateRoute.page, path: 'goals/new'),
        AutoRoute(page: GoalDetailRoute.page, path: 'goals/:goalId'),
        AutoRoute(page: GoalEditRoute.page, path: 'goals/:goalId/edit'),
        AutoRoute(page: RecurringRoute.page, path: 'recurring'),
        AutoRoute(page: RecurringCreateRoute.page, path: 'recurring/new'),
        AutoRoute(
          page: RecurringEditRoute.page,
          path: 'recurring/:recurringId/edit',
        ),
        AutoRoute(page: DebtsRoute.page, path: 'debts'),
        AutoRoute(page: DebtDetailRoute.page, path: 'debts/:debtId'),
        AutoRoute(page: CategoriesRoute.page, path: 'categories'),
        AutoRoute(page: CategoryCreateRoute.page, path: 'categories/new'),
        AutoRoute(
          page: CategoryEditRoute.page,
          path: 'categories/:categoryId/edit',
        ),
      ],
    ),
  ];
}
