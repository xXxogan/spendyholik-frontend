import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/total_balance_cubit.dart';
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
            TotalBalanceLoading() => const _BalanceSkeleton(),
            TotalBalanceError(:final failure) => FailureView(
              failure: failure,
              onRetry: context.read<TotalBalanceCubit>().load,
            ),
            TotalBalanceLoaded(:final balance) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.dashboardTotalBalance,
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMoney(balance.total, _currency, locale),
                  style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.dashboardMonthDelta(
                    formatMoney(balance.monthDelta, _currency, locale, signed: true),
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

          return Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(padding: const EdgeInsets.all(20), child: content),
          );
        },
      ),
    );
  }
}

class _BalanceSkeleton extends StatelessWidget {
  const _BalanceSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [bar(120, 14), const SizedBox(height: 10), bar(220, 36), const SizedBox(height: 10), bar(160, 14)],
      ),
    );
  }
}
