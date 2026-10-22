import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/accounts.dart';

@RoutePage()
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseLayout.slivers(
      slivers: [
        ContentSliverPadding(
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: .only(top: 12, bottom: 120),
              child: TwoColumnLayout(
                primary: [TotalBalanceCard()],
                secondary: [AccountsSection()],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
