import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/content_card.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

class AccountTrendCard extends StatelessWidget {
  const AccountTrendCard({
    super.key,
    required this.account,
    required this.history,
    required this.currency,
  });

  final AccountModel account;
  final List<BalancePoint> history;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ContentCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(
            context.l10n.accountDetailTrend,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          BalanceChart(
            history: history,
            color: AppColors.entity(account.color, theme.brightness),
            currency: currency,
          ),
        ],
      ),
    );
  }
}
