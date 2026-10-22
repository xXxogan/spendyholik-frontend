import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
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
  });

  final TransactionFilter filter;
  final String title;
  final String? actionLabel;
  final VoidCallback? onSeeAll;

  // Базовая валюта придёт из SessionCubit вместе с фичей user (T-28).
  static const _currency = Currency.rub;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    return BlocProvider(
      create: (_) => getIt<TransactionsCubit>()..load(filter),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          SectionHeader(
            title: title,
            actionLabel: actionLabel,
            onAction: onSeeAll,
          ),
          BlocBuilder<TransactionsCubit, TransactionsState>(
            builder: (context, state) => switch (state) {
              TransactionsLoading() => const SkeletonList(itemCount: 3),
              TransactionsLoaded(:final groups) => ContentCard(
                child: Column(
                  children: [
                    for (final group in groups)
                      for (final transaction in group.items)
                        TransactionTile(
                          transaction: transaction,
                          currency: _currency,
                          subtitle: [
                            formatDayLabel(
                              group.day,
                              DateTime.now(),
                              l10n,
                              locale,
                            ),
                            transaction.account.name,
                          ].join(' · '),
                        ),
                  ],
                ),
              ),
              TransactionsEmpty() => Text(l10n.transactionsNone),
              TransactionsError(:final failure) => FailureView(
                failure: failure,
                onRetry: () => context.read<TransactionsCubit>().load(filter),
              ),
            },
          ),
        ],
      ),
    );
  }
}
