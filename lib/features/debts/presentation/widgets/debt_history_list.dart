import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

class DebtHistoryList extends StatelessWidget {
  const DebtHistoryList({
    super.key,
    required this.debt,
    required this.history,
    required this.currency,
  });

  final DebtModel debt;
  final List<DebtEvent> history;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final today = DateTime.now();
    final isIOwe = debt.direction == DebtDirection.iOwe;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(title: l10n.debtHistory),
        ContentCard(
          child: Column(
            spacing: 14,
            children: [
              for (final event in history)
                Row(
                  spacing: 12,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      child: Icon(
                        event.kind == DebtEventKind.opened
                            ? Icons.handshake_outlined
                            : Icons.swap_horiz,
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(switch ((event.kind, isIOwe)) {
                            (DebtEventKind.opened, true) =>
                              l10n.debtEventBorrowed,
                            (DebtEventKind.opened, false) => l10n.debtEventLent,
                            (DebtEventKind.repayment, _) =>
                              l10n.debtEventRepayment,
                          }, style: theme.textTheme.bodyLarge),
                          Text(
                            [
                              ?event.account?.name,
                              formatDayLabel(event.date, today, l10n, locale),
                            ].join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: .ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatMoney(event.amount, currency, locale),
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
