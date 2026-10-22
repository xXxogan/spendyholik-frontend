import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:spendyholik/features/accounts/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AccountsCubit>()..load(),
      child: const AccountsView(),
    );
  }
}

class AccountsView extends StatelessWidget {
  const AccountsView({super.key});

  // Базовая валюта придёт из SessionCubit вместе с фичей user (шаг 7 плана).
  static const _currency = Currency.rub;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AccountsCubit>();
    final state = context.watch<AccountsCubit>().state;
    final filter = switch (state) {
      AccountsLoaded(:final filter) || AccountsEmpty(:final filter) => filter,
      _ => null,
    };

    return AppGlassScaffold(
      leading: const BackButton(),
      title: Text(context.l10n.accountsTitle),
      body: BaseLayout.slivers(
        slivers: [
          ContentSliverPadding(
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: AccountsFilterChips(selected: filter, onSelected: cubit.setFilter),
              ),
            ),
          ),
          switch (state) {
            AccountsLoading() => const SliverToBoxAdapter(child: SkeletonList()),
            AccountsLoaded(:final accounts) => ContentSliverPadding(
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 560,
                  mainAxisExtent: 76,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: accounts.length,
                itemBuilder: (_, index) => AccountTile(account: accounts[index], currency: _currency),
              ),
            ),
            AccountsEmpty() => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(context.l10n.accountsEmpty)),
            ),
            AccountsError(:final failure) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: FailureView(failure: failure, onRetry: cubit.load)),
            ),
          },
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
