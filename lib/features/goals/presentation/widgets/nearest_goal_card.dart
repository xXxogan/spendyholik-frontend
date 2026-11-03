import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/goals/data/models/models.dart';
import 'package:spendyholik/features/goals/presentation/cubit/goals_cubit.dart';
import 'package:spendyholik/features/goals/presentation/widgets/goal_progress_bar.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Блок Главной; нет незавершённых целей — блока нет.
class NearestGoalCard extends StatelessWidget {
  const NearestGoalCard({super.key});

  // Базовая валюта придёт из SessionCubit вместе с фичей user (T-28).
  static const _currency = Currency.rub;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GoalsCubit>()..load(),
      child: BlocBuilder<GoalsCubit, GoalsState>(
        builder: (context, state) {
          final cubit = context.read<GoalsCubit>();
          return switch (state) {
            GoalsLoading() => const SkeletonList(itemCount: 1, itemHeight: 120),
            GoalsError(:final failure) => FailureView(
              failure: failure,
              onRetry: cubit.load,
            ),
            GoalsLoaded() || GoalsEmpty() => switch (cubit.nearest) {
              final goal? => _content(context, goal),
              null => const SizedBox.shrink(),
            },
          };
        },
      ),
    );
  }

  Widget _content(BuildContext context, GoalModel goal) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return GestureDetector(
      onTap: () => context.router.push(GoalDetailRoute(goalId: goal.id)),
      behavior: .opaque,
      child: ContentCard(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Row(
              spacing: 12,
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.16,
                  ),
                  foregroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.flag_outlined),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        l10n.dashboardNearestGoal(goal.name),
                        style: muted,
                        overflow: .ellipsis,
                      ),
                      Text(
                        l10n.goalRemaining(
                          formatMoney(goal.remaining, _currency, locale),
                        ),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GoalProgressBar(goal: goal),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text(formatMoney(goal.saved, _currency, locale), style: muted),
                Text(formatMoney(goal.target, _currency, locale), style: muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
