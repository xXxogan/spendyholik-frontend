import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/budgets/presentation/cubit/budgets_tab_cubit.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// «+» в шапке вкладки: новый бюджет или новая цель — по открытому сегменту.
class BudgetsAddButton extends StatelessWidget {
  const BudgetsAddButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<BudgetsTabCubit, BudgetsTab>(
      bloc: getIt<BudgetsTabCubit>(),
      builder: (context, tab) => AppGlassIconButton(
        icon: Icons.add,
        tooltip: switch (tab) {
          BudgetsTab.budgets => l10n.budgetsAdd,
          BudgetsTab.goals => l10n.goalsAdd,
        },
        onPressed: () => context.router.push(switch (tab) {
          BudgetsTab.budgets => const BudgetCreateRoute(),
          BudgetsTab.goals => const GoalCreateRoute(),
        }),
      ),
    );
  }
}
