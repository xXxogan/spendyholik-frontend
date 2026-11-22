import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/presentation/widgets/transaction_amount.dart';
import 'package:spendyholik/features/transactions/presentation/widgets/transaction_info_row.dart';
import 'package:spendyholik/l10n/l10n.dart';

class TransactionDetailContent extends StatelessWidget {
  const TransactionDetailContent({
    super.key,
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
    final dayAndTime = t.hasTime
        ? '$day · ${DateFormat.Hm(locale).format(t.occurredAt)}'
        : day;

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
              dayAndTime,
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
                TransactionInfoRow(
                  l10n.transactionDetailCategory,
                  category.name,
                ),
              if (t.toAccount case final to?) ...[
                TransactionInfoRow(l10n.transactionDetailFrom, t.account.name),
                TransactionInfoRow(l10n.transactionDetailTo, to.name),
              ] else
                TransactionInfoRow(
                  l10n.transactionDetailAccount,
                  t.account.name,
                ),
              TransactionInfoRow(l10n.transactionDetailType, typeLabel),
              if (t.note case final note? when note.isNotEmpty)
                TransactionInfoRow(l10n.transactionDetailNote, note),
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
