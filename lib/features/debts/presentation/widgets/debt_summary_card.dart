import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';
import 'package:spendyholik/features/debts/presentation/widgets/debt_amount.dart';
import 'package:spendyholik/features/debts/presentation/widgets/debt_summary_row.dart';
import 'package:spendyholik/l10n/l10n.dart';

class DebtSummaryCard extends StatelessWidget {
  const DebtSummaryCard({
    super.key,
    required this.debt,
    required this.currency,
  });

  final DebtModel debt;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final locale = Localizations.localeOf(context).toString();
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final (amount, amountColor) = debtAmount(
      debt,
      currency,
      locale,
      brightness,
    );
    final isIOwe = debt.direction == DebtDirection.iOwe;
    final accent = isIOwe
        ? AppColors.negative(brightness)
        : AppColors.positive(brightness);
    final due = debt.dueDate;
    final overdue = debt.isOverdue(DateTime.now());

    return ContentCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 26,
              backgroundColor: accent.withValues(alpha: 0.16),
              foregroundColor: accent,
              child: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            textAlign: .center,
            style: theme.textTheme.headlineLarge?.copyWith(color: amountColor),
          ),
          Text(
            debt.counterparty,
            textAlign: .center,
            style: theme.textTheme.titleMedium,
          ),
          Text(
            [
              isIOwe ? l10n.debtsIOwe : l10n.debtsOwedToMe,
              if (debt.isClosed)
                l10n.debtClosed
              else if (!overdue && due != null)
                l10n.debtDue(DateFormat.MMMMd(locale).format(due)),
            ].join(' · '),
            textAlign: .center,
            style: muted,
          ),
          if (overdue)
            Text(
              l10n.debtOverdue,
              textAlign: .center,
              style: muted?.copyWith(color: AppColors.negative(brightness)),
            ),
          const SizedBox(height: 16),
          DebtSummaryRow(
            l10n.debtDetailTotal,
            formatMoney(debt.total, currency, locale),
          ),
          DebtSummaryRow(
            l10n.debtDetailRemaining,
            formatMoney(debt.remaining, currency, locale),
          ),
          if (due != null)
            DebtSummaryRow(
              l10n.debtDetailDue,
              DateFormat.yMMMMd(locale).format(due),
            ),
          if (debt.note case final note? when note.isNotEmpty)
            DebtSummaryRow(l10n.debtDetailNote, note),
        ],
      ),
    );
  }
}
