import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transaction_detail_cubit.dart';
import 'package:spendyholik/features/transactions/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({
    super.key,
    @PathParam('transactionId') required this.transactionId,
  });

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionDetailCubit>()..load(transactionId),
      child: const TransactionDetailView(),
    );
  }
}

class TransactionDetailView extends StatelessWidget {
  const TransactionDetailView({super.key});

  static const _maxWidth = 560.0;
  static const _fallback = TabsRoute(children: [TransactionsRoute()]);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionDetailCubit>();

    return BlocConsumer<TransactionDetailCubit, TransactionDetailState>(
      listenWhen: (_, state) => state is TransactionDetailDeleted,
      listener: (context, _) {
        showAppToast(context, context.l10n.transactionDeleted);
        navigateBack(context.router, _fallback);
      },
      builder: (context, state) {
        final transaction = switch (state) {
          TransactionDetailLoaded(:final transaction) => transaction,
          _ => null,
        };
        final title = transaction == null
            ? null
            : transaction.title.isNotEmpty
            ? transaction.title
            : transaction.category?.name ??
                  context.l10n.transactionTypeTransfer;

        return AppGlassScaffold(
          leading: const AppBackButton(fallback: _fallback),
          title: title,
          largeTitle: title != null,
          actions: [
            if (transaction != null)
              AppGlassIconButton(
                icon: Icons.edit_outlined,
                tooltip: context.l10n.transactionEditAction,
                onPressed: () => context.router.push(
                  TransactionEditRoute(transactionId: transaction.id),
                ),
              ),
          ],
          body: BaseLayout.slivers(
            largeTitle: title,
            slivers: [
              switch (state) {
                TransactionDetailLoaded(:final transaction) =>
                  ContentSliverPadding(
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _maxWidth,
                          ),
                          child: Padding(
                            padding: const .only(top: 12, bottom: 120),
                            child: TransactionDetailContent(
                              transaction: transaction,
                              currency: transaction.currency,
                              onDelete: cubit.delete,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                TransactionDetailError(:final failure) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: FailureView(failure: failure, onRetry: cubit.reload),
                  ),
                ),
                TransactionDetailLoading() ||
                TransactionDetailDeleted() => const SliverToBoxAdapter(
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
