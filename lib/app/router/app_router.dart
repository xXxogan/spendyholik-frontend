import 'package:auto_route/auto_route.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/app/router/guards.dart';
import 'package:spendyholik/features/user/user.dart';

@lazySingleton
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter(this._session);

  final SessionCubit _session;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, path: '/splash', initial: true),
    AutoRoute(page: OnboardingRoute.page, path: '/onboarding'),
    AutoRoute(
      page: LoginRoute.page,
      path: '/login',
      guards: [GuestGuard(_session)],
    ),
    AutoRoute(
      page: RegisterRoute.page,
      path: '/register',
      guards: [GuestGuard(_session)],
    ),
    AutoRoute(
      page: ForgotPasswordRoute.page,
      path: '/forgot-password',
      guards: [GuestGuard(_session)],
    ),
    AutoRoute(page: PrivacyPolicyRoute.page, path: '/privacy'),
    AutoRoute(
      page: EmailConfirmRoute.page,
      path: '/confirm-email',
      guards: [EmailConfirmGuard(_session)],
    ),
    AutoRoute(
      page: CurrencyRoute.page,
      path: '/currency',
      guards: [SessionGuard(_session)],
    ),
    AutoRoute(
      page: HomeRoute.page,
      path: '/',
      guards: [AuthGuard(_session)],
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
        AutoRoute(page: DebtCreateRoute.page, path: 'debts/new'),
        AutoRoute(page: DebtDetailRoute.page, path: 'debts/:debtId'),
        AutoRoute(page: DebtEditRoute.page, path: 'debts/:debtId/edit'),
        AutoRoute(page: NotificationsRoute.page, path: 'notifications'),
        AutoRoute(page: ProfileEditRoute.page, path: 'profile/edit'),
        AutoRoute(page: PasswordChangeRoute.page, path: 'profile/password'),
        AutoRoute(page: SettingsRoute.page, path: 'settings'),
        AutoRoute(page: AboutRoute.page, path: 'about'),
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
