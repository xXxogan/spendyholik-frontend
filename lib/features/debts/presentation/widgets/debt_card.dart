import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';
import 'package:spendyholik/features/debts/presentation/widgets/debt_amount.dart';
import 'package:spendyholik/l10n/l10n.dart';

class DebtCard extends StatelessWidget {
  const DebtCard({
    super.key,
    required this.debt,
    required this.currency,
    this.onTap,
  });

  final DebtModel debt;
  final Currency currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final locale = Localizations.localeOf(context).toString();
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final isIOwe = debt.direction == DebtDirection.iOwe;
    final accent = isIOwe
        ? AppColors.negative(brightness)
        : AppColors.positive(brightness);
    final due = debt.dueDate;
    final overdue = debt.isOverdue(DateTime.now());
    final note = debt.note;
    final (amount, amountColor) = debtAmount(
      debt,
      currency,
      locale,
      brightness,
    );

    final details = <(String, {bool alert})>[
      if (note != null && note.isNotEmpty) (note, alert: false),
      if (debt.isClosed)
        (l10n.debtClosed, alert: false)
      else if (overdue)
        (l10n.debtOverdue, alert: true)
      else if (due != null)
        (l10n.debtDue(DateFormat.MMMMd(locale).format(due)), alert: false),
    ];

    return Opacity(
      opacity: debt.isClosed ? 0.6 : 1,
      child: Card(
        margin: .zero,
        clipBehavior: .antiAlias,
        elevation: 0,
        color: theme.colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const .all(16),
            child: Row(
              spacing: 12,
              children: [
                CircleAvatar(
                  backgroundColor: accent.withValues(alpha: 0.16),
                  foregroundColor: accent,
                  child: const Icon(Icons.person_outline),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        debt.counterparty,
                        style: theme.textTheme.titleMedium,
                        overflow: .ellipsis,
                      ),
                      if (details.isNotEmpty)
                        Text.rich(
                          TextSpan(
                            children: [
                              for (final (i, (text, :alert))
                                  in details.indexed) ...[
                                if (i > 0) const TextSpan(text: ' · '),
                                TextSpan(
                                  text: text,
                                  style: alert
                                      ? TextStyle(
                                          color: AppColors.negative(brightness),
                                        )
                                      : null,
                                ),
                              ],
                            ],
                          ),
                          style: muted,
                          maxLines: 2,
                          overflow: .ellipsis,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: .end,
                  mainAxisSize: .min,
                  children: [
                    Text(
                      amount,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color:
                            amountColor ?? theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (!debt.isClosed && debt.remaining < debt.total)
                      Text(
                        l10n.debtOfTotal(
                          formatMoney(debt.total, currency, locale),
                        ),
                        style: muted,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
