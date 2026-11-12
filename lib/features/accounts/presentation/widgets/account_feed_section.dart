import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/account_feed_cubit.dart';
import 'package:spendyholik/features/accounts/presentation/widgets/feed_event_tile.dart';
import 'package:spendyholik/features/transactions/transactions.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Лента счёта: операции, долговые события и пополнения целей одним списком;
/// день — в подписи строки, как в `TransactionsSection`.
class AccountFeedSection extends StatelessWidget {
  const AccountFeedSection.sliver({
    super.key,
    required this.accountId,
    required this.title,
  });

  final String accountId;
  final String title;

  static const _cardPadding = 20.0;
  static const _cardRadius = 24.0;
  static const _loadMoreThreshold = 5;

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<AccountFeedCubit, AccountFeedState>(
      builder: (context, state) => switch (state) {
        AccountFeedLoaded() => _rows(context, state),
        _ => SliverToBoxAdapter(child: _placeholder(context, state)),
      },
    );

    return BlocProvider(
      // Родитель держит секцию под GlobalKey (TwoColumnLayout) — без ключа
      // другой счёт не дошёл бы до Cubit.
      key: ValueKey(accountId),
      create: (_) => getIt<AccountFeedCubit>()..load(accountId),
      child: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(child: SectionHeader(title: title)),
          body,
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context, AccountFeedState state) =>
      switch (state) {
        AccountFeedEmpty() => Text(context.l10n.transactionsNone),
        AccountFeedError(:final failure) => FailureView(
          failure: failure,
          onRetry: () => context.read<AccountFeedCubit>().load(accountId),
        ),
        AccountFeedLoading() ||
        AccountFeedLoaded() => const SkeletonList(itemCount: 3),
      };

  Widget _rows(BuildContext context, AccountFeedLoaded state) {
    final rows = [
      for (final group in state.groups)
        for (final entry in group.items) (group.day, entry),
    ];
    final showFooter = state.loadingMore || state.moreFailure != null;

    // Тот же вид, что у ContentCard, но список внутри ленивый.
    return DecoratedSliver(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: .circular(_cardRadius),
      ),
      sliver: SliverPadding(
        padding: const .all(_cardPadding),
        sliver: SliverList.builder(
          itemCount: rows.length + (showFooter ? 1 : 0),
          itemBuilder: (_, index) {
            if (index == rows.length) {
              return TransactionsLoadMoreRow(
                failed: !state.loadingMore,
                onRetry: context.read<AccountFeedCubit>().loadMore,
              );
            }
            // Cubit сам игнорирует повторы и конец списка; emit прямо во время
            // сборки сломал бы BlocBuilder. После ошибки — только по
            // «Повторить», иначе без сети каждая перестройка — новый запрос.
            if (state.moreFailure == null &&
                index >= rows.length - _loadMoreThreshold) {
              final cubit = context.read<AccountFeedCubit>();
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => cubit.autoLoadMore(),
              );
            }
            return _tile(context, rows[index].$1, rows[index].$2);
          },
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, DateTime day, FeedEntry entry) {
    final locale = Localizations.localeOf(context).toString();
    final dayLabel = formatDayLabel(day, DateTime.now(), context.l10n, locale);

    return switch (entry) {
      FeedTransaction(:final transaction) => TransactionTile(
        transaction: transaction,
        currency: transaction.currency,
        onTap: () => context.router.push(
          TransactionDetailRoute(transactionId: transaction.id),
        ),
        subtitle: [dayLabel, transaction.account.name].join(' · '),
      ),
      FeedDebtEvent(:final debtId) => FeedEventTile(
        entry: entry,
        subtitle: dayLabel,
        onTap: () => context.router.push(DebtDetailRoute(debtId: debtId)),
      ),
      FeedGoalContribution(:final goalId) => FeedEventTile(
        entry: entry,
        subtitle: dayLabel,
        onTap: () => context.router.push(GoalDetailRoute(goalId: goalId)),
      ),
    };
  }
}
