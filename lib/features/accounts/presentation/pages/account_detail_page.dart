import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/account_detail_cubit.dart';
import 'package:spendyholik/features/accounts/presentation/widgets/widgets.dart';
import 'package:spendyholik/features/transactions/transactions.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({
    super.key,
    @PathParam('accountId') required this.accountId,
  });

  final String accountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AccountDetailCubit>()..load(accountId),
      child: const AccountDetailView(),
    );
  }
}

class AccountDetailView extends StatelessWidget {
  const AccountDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AccountDetailCubit>();

    return BlocConsumer<AccountDetailCubit, AccountDetailState>(
      listenWhen: (_, state) => state is AccountDetailArchived,
      listener: (context, _) =>
          navigateBack(context.router, const AccountsRoute()),
      builder: (context, state) {
        final account = switch (state) {
          AccountDetailLoaded(:final account) => account,
          _ => null,
        };

        return AppGlassScaffold(
          leading: const AppBackButton(fallback: AccountsRoute()),
          title: account?.name,
          largeTitle: account != null,
          actions: [
            if (account != null)
              AppGlassIconButton(
                icon: Icons.edit_outlined,
                tooltip: context.l10n.accountEditAction,
                onPressed: () => context.router.push(
                  AccountEditRoute(accountId: account.id),
                ),
              ),
          ],
          body: BaseLayout.slivers(
            largeTitle: account?.name,
            slivers: [
              switch (state) {
                AccountDetailLoaded(:final account, :final history) =>
                  ContentSliverPadding(
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const .only(top: 12, bottom: 120),
                        child: TwoColumnLayout(
                          primary: [
                            AccountBalanceCard(
                              account: account,
                              currency: CurrencyScope.of(context),
                            ),
                            if (account.isArchived)
                              AccountUnarchiveButton(
                                onUnarchive: cubit.unarchive,
                              )
                            else
                              AccountArchiveButton(onArchive: cubit.archive),
                          ],
                          secondary: [
                            AccountTrendCard(
                              account: account,
                              history: history,
                              currency: CurrencyScope.of(context),
                            ),
                            TransactionsSection(
                              filter: TransactionFilter(accountId: account.id),
                              title: context.l10n.accountDetailTransactions,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                AccountDetailError(:final failure) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: FailureView(failure: failure, onRetry: cubit.reload),
                  ),
                ),
                AccountDetailLoading() ||
                AccountDetailArchived() => const SliverToBoxAdapter(
                  child: SkeletonList(itemCount: 3, itemHeight: 120),
                ),
              },
            ],
          ),
        );
      },
    );
  }
}
