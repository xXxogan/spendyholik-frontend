import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:spendyholik/features/accounts/presentation/widgets/account_tile.dart';
import 'package:spendyholik/l10n/l10n.dart';

class AccountsSection extends StatelessWidget {
  const AccountsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AccountsCubit>()
        ..setFilter(AccountsFilter.active)
        ..load(),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          SectionHeader(
            title: context.l10n.accountsTitle,
            actionLabel: context.l10n.dashboardAllAccounts,
            onAction: () => context.router.push(const AccountsRoute()),
          ),
          BlocBuilder<AccountsCubit, AccountsState>(
            builder: (context, state) => switch (state) {
              AccountsLoading() => const SkeletonList(itemCount: 4),
              AccountsLoaded(:final accounts) => Column(
                children: [
                  for (final account in accounts)
                    Padding(
                      padding: const .only(bottom: 8),
                      child: SizedBox(
                        height: 72,
                        child: AccountTile(
                          account: account,
                          currency: account.currency,
                          onTap: () => context.router.push(
                            AccountDetailRoute(accountId: account.id),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              AccountsEmpty() => Text(context.l10n.accountsEmpty),
              AccountsError(:final failure) => FailureView(
                failure: failure,
                onRetry: context.read<AccountsCubit>().load,
              ),
            },
          ),
        ],
      ),
    );
  }
}
