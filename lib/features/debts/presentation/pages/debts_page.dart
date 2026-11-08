import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';
import 'package:spendyholik/features/debts/presentation/cubit/debts_cubit.dart';
import 'package:spendyholik/features/debts/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class DebtsPage extends StatelessWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DebtsCubit>()..load(),
      child: const DebtsView(),
    );
  }
}

class DebtsView extends StatelessWidget {
  const DebtsView({super.key});

  static const _segmentsMaxWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<DebtsCubit>();
    final state = context.watch<DebtsCubit>().state;
    final title = l10n.debtsTitle;
    // Пока список грузится или упал, сегмент всё равно показывает выбор.
    final direction = switch (state) {
      DebtsLoaded(:final direction) => direction,
      DebtsEmpty(:final direction) => direction,
      _ => DebtDirection.iOwe,
    };

    return AppGlassScaffold(
      leading: const AppBackButton(
        fallback: TabsRoute(children: [ProfileRoute()]),
      ),
      title: title,
      largeTitle: true,
      actions: [
        AppGlassIconButton(
          icon: Icons.add,
          tooltip: l10n.debtsAdd,
          onPressed: () =>
              context.router.push(DebtCreateRoute(initialDirection: direction)),
        ),
      ],
      body: BaseLayout.slivers(
        largeTitle: title,
        slivers: [
          ContentSliverPadding(
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: .centerLeft,
                child: Padding(
                  padding: const .symmetric(vertical: 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _segmentsMaxWidth,
                    ),
                    child: DebtsDirectionSegment(
                      selected: direction,
                      onSelected: cubit.setDirection,
                    ),
                  ),
                ),
              ),
            ),
          ),
          switch (state) {
            DebtsLoading() => const SliverToBoxAdapter(
              child: SkeletonList(itemCount: 4, itemHeight: 88),
            ),
            DebtsLoaded(:final visible) => ContentSliverPadding(
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 560,
                  mainAxisExtent: 92,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: visible.length,
                itemBuilder: (context, index) => DebtCard(
                  debt: visible[index],
                  currency: visible[index].currency,
                  onTap: () => context.router.push(
                    DebtDetailRoute(debtId: visible[index].id),
                  ),
                ),
              ),
            ),
            DebtsEmpty() => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(l10n.debtsEmpty)),
            ),
            DebtsError(:final failure) => SliverFillRemaining(
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
