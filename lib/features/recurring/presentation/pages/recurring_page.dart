import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/recurring/presentation/cubit/recurring_cubit.dart';
import 'package:spendyholik/features/recurring/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RecurringCubit>()..load(),
      child: const RecurringView(),
    );
  }
}

class RecurringView extends StatelessWidget {
  const RecurringView({super.key});

  // Базовая валюта придёт из SessionCubit вместе с фичей user (T-28).
  static const _currency = Currency.rub;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<RecurringCubit>();
    final state = context.watch<RecurringCubit>().state;
    final title = l10n.recurringTitle;

    return AppGlassScaffold(
      leading: const AppBackButton(
        fallback: TabsRoute(children: [ProfileRoute()]),
      ),
      title: title,
      largeTitle: true,
      actions: [
        AppGlassIconButton(
          icon: Icons.add,
          tooltip: l10n.recurringAdd,
          onPressed: () => context.router.push(const RecurringCreateRoute()),
        ),
      ],
      body: BaseLayout.slivers(
        largeTitle: title,
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          switch (state) {
            RecurringLoading() => const SliverToBoxAdapter(
              child: SkeletonList(itemCount: 4, itemHeight: 120),
            ),
            RecurringLoaded(:final templates) => ContentSliverPadding(
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 560,
                  mainAxisExtent: 124,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: templates.length,
                itemBuilder: (context, index) => RecurringCard(
                  template: templates[index],
                  onTap: () => context.router.push(
                    RecurringEditRoute(recurringId: templates[index].id),
                  ),
                  currency: _currency,
                  onTogglePause: () => cubit.togglePause(templates[index].id),
                ),
              ),
            ),
            RecurringEmpty() => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(l10n.recurringEmpty)),
            ),
            RecurringError(:final failure) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: FailureView(failure: failure, onRetry: cubit.load),
              ),
            ),
          },
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
