import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

class TransactionDaySection extends StatelessWidget {
  const TransactionDaySection({
    super.key,
    required this.group,
    required this.currency,
  });

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
