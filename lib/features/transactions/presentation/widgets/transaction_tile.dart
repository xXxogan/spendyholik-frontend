import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/presentation/widgets/transaction_amount.dart';
import 'package:spendyholik/l10n/l10n.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.currency,
    this.subtitle,
    this.onTap,
  });

  final TransactionModel transaction;
  final Currency currency;

  /// По умолчанию — «Категория · Счёт», у перевода — «Откуда → Куда».
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final locale = Localizations.localeOf(context).toString();
    final t = transaction;
    final category = t.category;

    // Без названия сервер отдаёт пустое (см. RemoteTransactionRepository).
    final title = t.title.isNotEmpty
        ? t.title
        : category?.name ?? context.l10n.transactionTypeTransfer;
    final (amount, amountColor) = transactionAmount(
      t,
      currency,
      locale,
      brightness,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: .circular(12),
      child: Padding(
        padding: const .symmetric(vertical: 8),
        child: Row(
          spacing: 12,
          children: [
            EntityIconView(
              icon: category?.icon ?? EntityIcon.transfer,
              color: AppColors.entity(
                category?.color ?? EntityColor.gray,
                brightness,
              ),
              size: 36,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    title,
                    overflow: .ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                  Text(
                    subtitle ?? _defaultSubtitle(),
                    overflow: .ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: theme.textTheme.titleSmall?.copyWith(color: amountColor),
            ),
          ],
        ),
      ),
    );
  }

  String _defaultSubtitle() => switch (transaction.toAccount) {
    final to? => '${transaction.account.name} → ${to.name}',
    null => [?transaction.category?.name, transaction.account.name].join(' · '),
  };
}
