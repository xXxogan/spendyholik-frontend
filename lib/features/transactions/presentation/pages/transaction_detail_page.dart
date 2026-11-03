import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transaction_detail_cubit.dart';
import 'package:spendyholik/features/transactions/presentation/widgets/transaction_amount.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({
    super.key,
    @PathParam('transactionId') required this.transactionId,
  });

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionDetailCubit>()..load(transactionId),
      child: const TransactionDetailView(),
    );
  }
}

class TransactionDetailView extends StatelessWidget {
  const TransactionDetailView({super.key});

  static const _maxWidth = 560.0;
  static const _fallback = TabsRoute(children: [TransactionsRoute()]);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionDetailCubit>();

    return BlocConsumer<TransactionDetailCubit, TransactionDetailState>(
      listenWhen: (_, state) => state is TransactionDetailDeleted,
      listener: (context, _) {
        showAppToast(context, context.l10n.transactionDeleted);
        navigateBack(context.router, _fallback);
      },
      builder: (context, state) {
        final transaction = switch (state) {
          TransactionDetailLoaded(:final transaction) => transaction,
          _ => null,
        };
        final title = transaction == null
            ? null
            : transaction.title.isEmpty
            ? transaction.category?.name
            : transaction.title;

        return AppGlassScaffold(
          leading: const AppBackButton(fallback: _fallback),
          title: title,
          largeTitle: title != null,
          actions: [
            if (transaction != null)
              AppGlassIconButton(
                icon: Icons.edit_outlined,
                tooltip: context.l10n.transactionEditAction,
                onPressed: () => context.router.push(
                  TransactionEditRoute(transactionId: transaction.id),
                ),
              ),
          ],
          body: BaseLayout.slivers(
            largeTitle: title,
            slivers: [
              switch (state) {
                TransactionDetailLoaded(:final transaction) =>
                  ContentSliverPadding(
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _maxWidth,
                          ),
                          child: Padding(
                            padding: const .only(top: 12, bottom: 120),
                            child: _Content(
                              transaction: transaction,
                              currency: CurrencyScope.of(context),
                              onDelete: cubit.delete,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                TransactionDetailError(:final failure) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: FailureView(failure: failure, onRetry: cubit.reload),
                  ),
                ),
                TransactionDetailLoading() ||
                TransactionDetailDeleted() => const SliverToBoxAdapter(
                  child: SkeletonList(itemCount: 3, itemHeight: 120),
                ),
              },
            ],
          ),
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.transaction,
    required this.currency,
    required this.onDelete,
  });

  final TransactionModel transaction;
  final Currency currency;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final locale = Localizations.localeOf(context).toString();
    final t = transaction;
    final category = t.category;
    final negative = AppColors.negative(brightness);

    // Знак и цвет суммы те же, что в TransactionTile.
    final (amount, amountColor) = transactionAmount(
      t,
      currency,
      locale,
      brightness,
    );
    final typeLabel = switch (t.type) {
      TransactionType.expense => l10n.transactionTypeExpense,
      TransactionType.income => l10n.transactionTypeIncome,
      TransactionType.transfer => l10n.transactionTypeTransfer,
    };
    final day = formatDayLabel(t.occurredAt, DateTime.now(), l10n, locale);
    final time = DateFormat.Hm(locale).format(t.occurredAt);

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        Column(
          spacing: 8,
          children: [
            EntityIconView(
              icon: category?.icon ?? EntityIcon.transfer,
              color: AppColors.entity(
                category?.color ?? EntityColor.gray,
                brightness,
              ),
              size: 56,
            ),
            Text(
              amount,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: amountColor,
              ),
            ),
            Text(
              '$day · $time',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        ContentCard(
          child: Column(
            spacing: 12,
            children: [
              if (category != null)
                _InfoRow(l10n.transactionDetailCategory, category.name),
              if (t.toAccount case final to?) ...[
                _InfoRow(l10n.transactionDetailFrom, t.account.name),
                _InfoRow(l10n.transactionDetailTo, to.name),
              ] else
                _InfoRow(l10n.transactionDetailAccount, t.account.name),
              _InfoRow(l10n.transactionDetailType, typeLabel),
              if (t.note case final note? when note.isNotEmpty)
                _InfoRow(l10n.transactionDetailNote, note),
            ],
          ),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.transactionDeleteAction),
          style: OutlinedButton.styleFrom(
            foregroundColor: negative,
            side: BorderSide(color: negative),
          ),
          onPressed: () async {
            final confirmed = await showAppConfirmDialog(
              context,
              title: l10n.transactionDeleteConfirmTitle,
              message: l10n.transactionDeleteConfirmMessage,
              confirmLabel: l10n.transactionDeleteAction,
              cancelLabel: l10n.commonCancel,
              destructive: true,
            );
            if (confirmed) onDelete();
          },
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: .start,
      spacing: 16,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(value, textAlign: .end, style: theme.textTheme.bodyLarge),
        ),
      ],
    );
  }
}
