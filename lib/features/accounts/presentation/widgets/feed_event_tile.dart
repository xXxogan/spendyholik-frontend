import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/data/models/feed_entry.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Долговое событие или пополнение цели в ленте счёта; вид — как у
/// `TransactionTile`.
class FeedEventTile extends StatelessWidget {
  const FeedEventTile({
    super.key,
    required this.entry,
    required this.subtitle,
    this.onTap,
  });

  /// Только [FeedDebtEvent] или [FeedGoalContribution].
  final FeedEntry entry;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    final (title, icon, color) = switch (entry) {
      FeedDebtEvent(:final personName, :final direction, :final opening) => (
        switch ((opening, direction)) {
          (false, _) => l10n.accountFeedDebtRepayment(personName),
          (true, .iOwe) => l10n.accountFeedDebtBorrowed(personName),
          (true, .owedToMe) => l10n.accountFeedDebtLent(personName),
        },
        EntityIcon.credit,
        EntityColor.orange,
      ),
      FeedGoalContribution(:final goalName) => (
        l10n.accountFeedGoalContribution(goalName),
        EntityIcon.savings,
        EntityColor.teal,
      ),
      FeedTransaction() => ('', EntityIcon.other, EntityColor.gray),
    };
    final (amount, amountColor) = switch (entry.effect) {
      .incoming => (
        formatMoney(entry.amount, entry.currency, locale, signed: true),
        AppColors.positive(brightness),
      ),
      .outgoing => (
        formatMoney(-entry.amount, entry.currency, locale),
        AppColors.negative(brightness),
      ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: .circular(12),
      child: Padding(
        padding: const .symmetric(vertical: 8),
        child: Row(
          spacing: 12,
          children: [
            EntityIconView(
              icon: icon,
              color: AppColors.entity(color, brightness),
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
                    subtitle,
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
}
