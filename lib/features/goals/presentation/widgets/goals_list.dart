import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/goals/presentation/cubit/goals_cubit.dart';
import 'package:spendyholik/features/goals/presentation/widgets/goal_card.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Сливер: ставится прямо в `CustomScrollView` вкладки «Бюджеты».
class GoalsList extends StatelessWidget {
  const GoalsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GoalsCubit>()..load(),
      child: BlocBuilder<GoalsCubit, GoalsState>(
        builder: (context, state) => switch (state) {
          GoalsLoading() => const SliverToBoxAdapter(
            child: SkeletonList(itemCount: 3, itemHeight: 100),
          ),
          GoalsLoaded(:final goals) => ContentSliverPadding(
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 560,
                mainAxisExtent: 98,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: goals.length,
              itemBuilder: (context, index) => GoalCard(
                goal: goals[index],
                currency: goals[index].currency,
                onTap: () => context.router.push(
                  GoalDetailRoute(goalId: goals[index].id),
                ),
              ),
            ),
          ),
          GoalsEmpty() => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(context.l10n.goalsEmpty)),
          ),
          GoalsError(:final failure) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: FailureView(
                failure: failure,
                onRetry: context.read<GoalsCubit>().load,
              ),
            ),
          ),
        },
      ),
    );
  }
}
