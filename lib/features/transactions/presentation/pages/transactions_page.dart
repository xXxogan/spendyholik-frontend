import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:spendyholik/features/transactions/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<TransactionsCubit>()..load(const TransactionFilter()),
      child: const TransactionsView(),
    );
  }
}

class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  static const _maxWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<TransactionsCubit>();
    final state = context.watch<TransactionsCubit>().state;
    final filter = switch (state) {
      TransactionsLoaded(:final filter) ||
      TransactionsEmpty(:final filter) => filter,
      _ => const TransactionFilter(),
    };

    Widget constrained(Widget child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: child,
      ),
    );

    return BaseLayout.slivers(
      largeTitle: l10n.navTransactions,
      slivers: [
        ContentSliverPadding(
          sliver: SliverToBoxAdapter(
            child: constrained(
              Padding(
                padding: const .symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: .start,
                  spacing: 8,
                  children: [
                    Expanded(
                      child: TransactionTypeChips(
                        selected: filter.type,
                        onSelected: cubit.setType,
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: l10n.transactionFiltersTitle,
                      icon: filter.withType(null) == const TransactionFilter()
                          ? const Icon(Icons.tune)
                          : const Badge(child: Icon(Icons.tune)),
                      onPressed: () async {
                        final applied = await showTransactionFiltersSheet(
                          context,
                          filter,
                        );
                        if (applied != null) await cubit.applyFilter(applied);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        switch (state) {
          TransactionsLoading() => const SliverToBoxAdapter(
            child: SkeletonList(),
          ),
          TransactionsLoaded(:final groups) => ContentSliverPadding(
            sliver: SliverList.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) => constrained(
                TransactionDaySection(
                  group: groups[index],
                  currency: CurrencyScope.of(context),
                ),
              ),
            ),
          ),
          TransactionsEmpty() => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: .min,
                spacing: 12,
                children: [
                  Text(
                    l10n.transactionsNothingFound,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  FilledButton.tonal(
                    onPressed: () =>
                        cubit.applyFilter(const TransactionFilter()),
                    child: Text(l10n.transactionsReset),
                  ),
                ],
              ),
            ),
          ),
          TransactionsError(:final failure) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: FailureView(
                failure: failure,
                onRetry: () => cubit.load(filter),
              ),
            ),
          ),
        },
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}
