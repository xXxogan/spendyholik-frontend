import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

const homeTabRoutes = <PageRouteInfo>[
  DashboardRoute(),
  TransactionsRoute(),
  AnalyticsRoute(),
  BudgetsRoute(),
  ProfileRoute(),
];

List<AppNavDestination> homeDestinations(AppLocalizations l10n) => [
  AppNavDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: l10n.navDashboard,
  ),
  AppNavDestination(
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    label: l10n.navTransactions,
  ),
  AppNavDestination(
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights,
    label: l10n.navAnalytics,
  ),
  AppNavDestination(
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
    label: l10n.navBudgets,
  ),
  AppNavDestination(
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: l10n.navProfile,
  ),
];

const homeLinkRoutes = <PageRouteInfo>[
  CategoriesRoute(),
  RecurringRoute(),
  DebtsRoute(),
  NotificationsRoute(),
];

List<AppNavDestination> homeLinks(AppLocalizations l10n) => [
  AppNavDestination(
    icon: Icons.category_outlined,
    selectedIcon: Icons.category,
    label: l10n.categoriesTitle,
  ),
  AppNavDestination(
    icon: Icons.event_repeat_outlined,
    selectedIcon: Icons.event_repeat,
    label: l10n.recurringTitle,
  ),
  AppNavDestination(
    icon: Icons.handshake_outlined,
    selectedIcon: Icons.handshake,
    label: l10n.debtsTitle,
  ),
  AppNavDestination(
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
    label: l10n.notificationsTitle,
  ),
];
