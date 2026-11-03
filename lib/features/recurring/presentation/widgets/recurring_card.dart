import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/recurring/data/models/models.dart';
import 'package:spendyholik/features/recurring/presentation/widgets/recurring_schedule_label.dart';
import 'package:spendyholik/features/transactions/transactions.dart';
import 'package:spendyholik/l10n/l10n.dart';

class RecurringCard extends StatelessWidget {
  const RecurringCard({
    super.key,
    required this.template,
    required this.currency,
    required this.onTogglePause,
  });

  final RecurringModel template;
  final Currency currency;
  final VoidCallback onTogglePause;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final locale = Localizations.localeOf(context).toString();
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final isIncome = template.type == TransactionType.income;
    final schedule = recurringScheduleLabel(context, template);

    return Opacity(
      opacity: template.isPaused ? 0.6 : 1,
      child: Card(
        margin: .zero,
        elevation: 0,
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const .fromLTRB(16, 16, 12, 8),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Row(
                spacing: 12,
                children: [
                  EntityIconView(
                    icon: template.category.icon,
                    color: AppColors.entity(
                      template.category.color,
                      brightness,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          template.title,
                          style: theme.textTheme.titleMedium,
                          overflow: .ellipsis,
                        ),
                        Text(
                          template.isPaused
                              ? l10n.recurringScheduleOnPause(schedule)
                              : schedule,
                          style: muted,
                          overflow: .ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    isIncome
                        ? formatMoney(
                            template.amount,
                            currency,
                            locale,
                            signed: true,
                          )
                        : formatMoney(-template.amount, currency, locale),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isIncome
                          ? AppColors.positive(brightness)
                          : AppColors.negative(brightness),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.isPaused
                          ? l10n.recurringPaused
                          : l10n.recurringNext(
                              formatDayLabel(
                                template.nextDate,
                                DateTime.now(),
                                l10n,
                                locale,
                              ),
                            ),
                      style: muted,
                    ),
                  ),
                  Switch(
                    value: !template.isPaused,
                    onChanged: (_) => onTogglePause(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
