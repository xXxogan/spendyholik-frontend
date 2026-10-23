import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/analytics/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

class CategoryShareList extends StatelessWidget {
  const CategoryShareList({
    super.key,
    required this.shares,
    required this.percents,
    required this.currency,
  });

  final List<CategoryShare> shares;

  /// Того же порядка, что [shares]; в сумме 100.
  final List<int> percents;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    return ContentCard(
      child: shares.isEmpty
          ? Text(context.l10n.analyticsNoExpenses)
          : Column(
              children: [
                for (var i = 0; i < shares.length; i++)
                  Padding(
                    padding: const .symmetric(vertical: 6),
                    child: Row(
                      spacing: 12,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: .circle,
                            color: AppColors.entity(
                              shares[i].category.color,
                              theme.brightness,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            shares[i].category.name,
                            overflow: .ellipsis,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        Text(
                          '${formatMoney(shares[i].amount, currency, locale)}'
                          ' · ${percents[i]}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
