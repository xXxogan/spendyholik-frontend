import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/goals/presentation/cubit/goal_detail_cubit.dart';
import 'package:spendyholik/features/goals/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class GoalDetailPage extends StatelessWidget {
  const GoalDetailPage({super.key, @PathParam('goalId') required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GoalDetailCubit>()..load(goalId),
      child: const GoalDetailView(),
    );
  }
}

class GoalDetailView extends StatelessWidget {
  const GoalDetailView({super.key});

  // Базовая валюта придёт из SessionCubit вместе с фичей user (T-28).
  static const _currency = Currency.rub;
  static const _fallback = TabsRoute(children: [BudgetsRoute()]);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final cubit = context.read<GoalDetailCubit>();
    final state = context.watch<GoalDetailCubit>().state;

    return AppGlassScaffold(
      leading: const AppBackButton(fallback: _fallback),
      title: l10n.goalDetailTitle,
      largeTitle: true,
      body: BaseLayout.slivers(
        largeTitle: l10n.goalDetailTitle,
        slivers: [
          switch (state) {
            GoalDetailLoaded(
              :final goal,
              :final contributions,
              :final forecastMonths,
            ) =>
              ContentSliverPadding(
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const .only(top: 12, bottom: 120),
                    child: TwoColumnLayout(
                      primary: [
                        GoalSummaryCard(goal: goal, currency: _currency),
                        Row(
                          spacing: 12,
                          crossAxisAlignment: .start,
                          children: [
                            Expanded(
                              child: GoalStatTile(
                                value: formatMoney(
                                  goal.remaining,
                                  _currency,
                                  locale,
                                ),
                                label: l10n.goalRemainingLabel,
                              ),
                            ),
                            Expanded(
                              child: GoalStatTile(
                                value: switch (forecastMonths) {
                                  null => l10n.goalForecastNone,
                                  0 => l10n.goalReachedTitle,
                                  final months => l10n.goalForecastMonths(
                                    months,
                                  ),
                                },
                                label: l10n.goalForecastLabel,
                              ),
                            ),
                          ],
                        ),
                        if (!goal.isReached)
                          FilledButton(
                            onPressed: () =>
                                showGoalTopUpSheet(context, goal.id),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                            child: Text(l10n.goalTopUpSubmit),
                          ),
                      ],
                      secondary: [
                        GoalContributionsList(
                          contributions: contributions,
                          currency: _currency,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            GoalDetailError(:final failure) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: FailureView(failure: failure, onRetry: cubit.reload),
              ),
            ),
            GoalDetailLoading() => const SliverToBoxAdapter(
              child: SkeletonList(itemCount: 3, itemHeight: 120),
            ),
          },
        ],
      ),
    );
  }
}
