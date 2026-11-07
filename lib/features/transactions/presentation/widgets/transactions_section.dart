import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:spendyholik/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Плоский список для Главной, счёта, бюджета: день — в подписи строки.
class TransactionsSection extends StatelessWidget {
  const TransactionsSection({
    super.key,
    required this.filter,
    required this.title,
    this.actionLabel,
    this.onSeeAll,
  }) : _sliver = false;

  /// Для полного списка (счёт, бюджет): строки строятся по мере прокрутки.
  const TransactionsSection.sliver({
    super.key,
    required this.filter,
    required this.title,
    this.actionLabel,
    this.onSeeAll,
  }) : _sliver = true;

  final TransactionFilter filter;
  final String title;
  final String? actionLabel;
  final VoidCallback? onSeeAll;
  final bool _sliver;

  static const _cardPadding = 20.0;
  static const _cardRadius = 24.0;

  @override
  Widget build(BuildContext context) {
    final header = SectionHeader(
      title: title,
      actionLabel: actionLabel,
      onAction: onSeeAll,
    );
    final body = BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) => switch (state) {
        TransactionsLoaded(:final groups) => _rows(context, groups),
        _ => _box(_placeholder(context, state)),
      },
    );

    return BlocProvider(
      // Родитель держит секцию под GlobalKey (TwoColumnLayout) — без ключа
      // новый фильтр (правка бюджета) не дошёл бы до Cubit.
      key: ValueKey(filter),
      create: (_) => getIt<TransactionsCubit>()..load(filter),
      child: _sliver
          ? SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(child: header),
                body,
              ],
            )
          : Column(crossAxisAlignment: .stretch, children: [header, body]),
    );
  }

  Widget _box(Widget child) =>
      _sliver ? SliverToBoxAdapter(child: child) : child;

  Widget _placeholder(BuildContext context, TransactionsState state) =>
      switch (state) {
        TransactionsEmpty() => Text(context.l10n.transactionsNone),
        TransactionsError(:final failure) => FailureView(
          failure: failure,
          onRetry: () => context.read<TransactionsCubit>().load(filter),
        ),
        TransactionsLoading() ||
        TransactionsLoaded() => const SkeletonList(itemCount: 3),
      };

  Widget _rows(BuildContext context, List<TransactionDayGroup> groups) {
    final rows = [
      for (final group in groups)
        for (final transaction in group.items) (group.day, transaction),
    ];
    Widget tile(int index) => _tile(context, rows[index].$1, rows[index].$2);

    if (!_sliver) {
      return ContentCard(
        child: Column(
          children: [for (var i = 0; i < rows.length; i++) tile(i)],
        ),
      );
    }
    // Тот же вид, что у ContentCard, но список внутри ленивый.
    return DecoratedSliver(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: .circular(_cardRadius),
      ),
      sliver: SliverPadding(
        padding: const .all(_cardPadding),
        sliver: SliverList.builder(
          itemCount: rows.length,
          itemBuilder: (_, index) => tile(index),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, DateTime day, TransactionModel item) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    return TransactionTile(
      transaction: item,
      currency: CurrencyScope.of(context),
      onTap: () =>
          context.router.push(TransactionDetailRoute(transactionId: item.id)),
      subtitle: [
        formatDayLabel(day, DateTime.now(), l10n, locale),
        item.account.name,
      ].join(' · '),
    );
  }
}
