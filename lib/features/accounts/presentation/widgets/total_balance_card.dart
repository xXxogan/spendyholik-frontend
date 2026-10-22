import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/total_balance_cubit.dart';
import 'package:spendyholik/features/accounts/presentation/widgets/total_balance_skeleton.dart';
import 'package:spendyholik/l10n/l10n.dart';

class TotalBalanceCard extends StatelessWidget {
  const TotalBalanceCard({super.key});

  // Базовая валюта придёт из SessionCubit вместе с фичей user (T-28).
  static const _currency = Currency.rub;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TotalBalanceCubit>()..load(),
      child: BlocBuilder<TotalBalanceCubit, TotalBalanceState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          final locale = Localizations.localeOf(context).toString();

          final content = switch (state) {
            TotalBalanceLoading() => const TotalBalanceSkeleton(),
            TotalBalanceError(:final failure) => FailureView(
              failure: failure,
              onRetry: context.read<TotalBalanceCubit>().load,
            ),
            TotalBalanceLoaded(:final balance) => Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  context.l10n.dashboardTotalBalance,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMoney(balance.total, _currency, locale),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: .w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.dashboardMonthDelta(
                    formatMoney(
                      balance.monthDelta,
                      _currency,
                      locale,
                      signed: true,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: balance.monthDelta < 0
                        ? AppColors.negative(theme.brightness)
                        : AppColors.positive(theme.brightness),
                  ),
                ),
              ],
            ),
          };

          return ContentCard(child: content);
        },
      ),
    );
  }
}
