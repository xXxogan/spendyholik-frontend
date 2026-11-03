import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/debts/presentation/cubit/debt_detail_cubit.dart';
import 'package:spendyholik/features/debts/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class DebtDetailPage extends StatelessWidget {
  const DebtDetailPage({super.key, @PathParam('debtId') required this.debtId});

  final String debtId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DebtDetailCubit>()..load(debtId),
      child: const DebtDetailView(),
    );
  }
}

class DebtDetailView extends StatelessWidget {
  const DebtDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<DebtDetailCubit>();
    final state = context.watch<DebtDetailCubit>().state;

    return AppGlassScaffold(
      leading: const AppBackButton(fallback: DebtsRoute()),
      title: l10n.debtDetailTitle,
      largeTitle: true,
      actions: [
        if (state case DebtDetailLoaded(:final debt))
          AppGlassIconButton(
            icon: Icons.edit_outlined,
            tooltip: l10n.debtEditAction,
            onPressed: () =>
                context.router.push(DebtEditRoute(debtId: debt.id)),
          ),
      ],
      body: BaseLayout.slivers(
        largeTitle: l10n.debtDetailTitle,
        slivers: [
          switch (state) {
            DebtDetailLoaded(:final debt, :final history) =>
              ContentSliverPadding(
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const .only(top: 12, bottom: 120),
                    child: TwoColumnLayout(
                      primary: [
                        DebtSummaryCard(
                          debt: debt,
                          currency: CurrencyScope.of(context),
                        ),
                        if (!debt.isClosed)
                          FilledButton(
                            onPressed: () => showDebtRepaySheet(context, debt),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                            child: Text(l10n.debtRepaySubmit),
                          ),
                      ],
                      secondary: [
                        DebtHistoryList(
                          debt: debt,
                          history: history,
                          currency: CurrencyScope.of(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            DebtDetailError(:final failure) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: FailureView(failure: failure, onRetry: cubit.reload),
              ),
            ),
            DebtDetailLoading() => const SliverToBoxAdapter(
              child: SkeletonList(itemCount: 3, itemHeight: 120),
            ),
          },
        ],
      ),
    );
  }
}
