import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/analytics/presentation/cubit/analytics_cubit.dart';
import 'package:spendyholik/features/analytics/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AnalyticsCubit>()..load(),
      child: const AnalyticsView(),
    );
  }
}

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  // Базовая валюта придёт из SessionCubit вместе с фичей user (T-28).
  static const _currency = Currency.rub;
  static const _maxWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AnalyticsCubit>();
    final state = context.watch<AnalyticsCubit>().state;
    final preset = switch (state) {
      AnalyticsLoading(:final preset) ||
      AnalyticsLoaded(:final preset) ||
      AnalyticsEmpty(:final preset) ||
      AnalyticsError(:final preset) => preset,
    };

    Widget constrained(Widget child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: child,
      ),
    );

    return BaseLayout.slivers(
      largeTitle: l10n.navAnalytics,
      slivers: [
        ContentSliverPadding(
          sliver: SliverToBoxAdapter(
            child: constrained(
              Padding(
                padding: const .symmetric(vertical: 12),
                child: SegmentedButton<PeriodPreset>(
                  segments: [
                    ButtonSegment(
                      value: PeriodPreset.week,
                      label: Text(l10n.periodWeek),
                    ),
                    ButtonSegment(
                      value: PeriodPreset.month,
                      label: Text(l10n.periodMonth),
                    ),
                    ButtonSegment(
                      value: PeriodPreset.year,
                      label: Text(l10n.periodYear),
                    ),
                  ],
                  selected: {preset},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      cubit.selectPeriod(selection.first),
                ),
              ),
            ),
          ),
        ),
        switch (state) {
          AnalyticsLoading() => const SliverToBoxAdapter(
            child: SkeletonList(itemCount: 4, itemHeight: 88),
          ),
          AnalyticsLoaded(:final report, :final percents) =>
            ContentSliverPadding(
              sliver: SliverToBoxAdapter(
                child: constrained(
                  Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      AnalyticsSummary(
                        report: report,
                        preset: preset,
                        currency: _currency,
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(title: l10n.analyticsByCategory),
                      CategoryShareList(
                        shares: report.expenseByCategory,
                        percents: percents,
                        currency: _currency,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          AnalyticsEmpty() => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                l10n.analyticsEmpty,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          AnalyticsError(:final failure) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: FailureView(failure: failure, onRetry: cubit.load),
            ),
          ),
        },
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}
