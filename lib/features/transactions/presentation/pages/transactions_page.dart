import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
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

  // Базовая валюта придёт из SessionCubit вместе с фичей user (T-28).
  static const _currency = Currency.rub;
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
                _DayGroup(group: groups[index], currency: _currency),
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

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.group, required this.currency});

  final TransactionDayGroup group;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    return Padding(
      padding: const .only(bottom: 16),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Padding(
            padding: const .only(left: 4, bottom: 8),
            child: Text(
              formatDayLabel(group.day, DateTime.now(), context.l10n, locale),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ContentCard(
            child: Column(
              children: [
                for (final transaction in group.items)
                  TransactionTile(
                    transaction: transaction,
                    currency: currency,
                    onTap: () => context.router.push(
                      TransactionDetailRoute(transactionId: transaction.id),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
