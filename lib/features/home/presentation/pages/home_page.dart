import 'package:auto_route/auto_route.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/features/home/presentation/widgets/widgets.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        GeneralRoute(),
        TransactionsRoute(),
        AnalyticsRoute(),
        BudgetRoute(),
        ProfileRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        final theme = Theme.of(context);

        final appBars = [
          GlassAppBar(
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: "Spendy", style: theme.textTheme.titleLarge),
                  TextSpan(
                    text: "Holik",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.person_2, color: theme.colorScheme.primary),
                onPressed: () {},
              ),
            ],
          ),
          GlassAppBar(title: Text("SpendyHolik")),
          GlassAppBar(title: Text("SpendyHolik")),
          GlassAppBar(title: Text("SpendyHolik")),
          GlassAppBar(title: Text("SpendyHolik")),
        ];

        return GlassScaffold(
          appBar: appBars[tabsRouter.activeIndex],
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          body: child,
          bottomBar: BottomNavBar(tabsRouter: tabsRouter),
        );
      },
    );
  }
}
