import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      children: [
        ListTile(
          leading: const Icon(Icons.account_balance_wallet_outlined),
          title: Text(context.l10n.dashboardAllAccounts),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.router.push(const AccountsRoute()),
        ),
        const SkeletonList(itemCount: 12),
      ],
    );
  }
}
