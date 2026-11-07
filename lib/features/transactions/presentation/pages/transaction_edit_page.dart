import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:spendyholik/features/transactions/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class TransactionEditPage extends StatelessWidget {
  const TransactionEditPage({
    super.key,
    @PathParam('transactionId') required this.transactionId,
  });

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionFormCubit>()..init(transactionId),
      child: const TransactionEditView(),
    );
  }
}

/// Форма и создания, и правки: режим задаёт `TransactionFormState.transactionId`.
class TransactionEditView extends StatelessWidget {
  const TransactionEditView({super.key});

  static const _formMaxWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<TransactionFormCubit>();

    return BlocConsumer<TransactionFormCubit, TransactionFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case FormStatus.success:
            showAppToast(context, l10n.transactionFormSaved);
            navigateBack(context.router, _fallback(state.transactionId));
          case FormStatus.failure:
            if (state.failure case final failure?) {
              showAppToast(context, failureMessage(l10n, failure), error: true);
            }
          case FormStatus.idle || FormStatus.submitting:
            break;
        }
      },
      builder: (context, state) {
        final title = state.transactionId == null
            ? l10n.transactionFormNewTitle
            : l10n.transactionFormEditTitle;

        return AppGlassScaffold(
          leading: AppBackButton(fallback: _fallback(state.transactionId)),
          title: title,
          largeTitle: true,
          body: BaseLayout.slivers(
            largeTitle: title,
            slivers: [
              if (state.loadFailed)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: FailureView(
                      failure: state.failure!,
                      onRetry: () => cubit.init(state.transactionId),
                    ),
                  ),
                )
              else if (state.isLoading || state.occurredAt == null)
                const SliverToBoxAdapter(
                  child: SkeletonList(itemCount: 5, itemHeight: 56),
                )
              else
                ContentSliverPadding(
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _formMaxWidth,
                        ),
                        child: Padding(
                          padding: const .only(top: 12, bottom: 120),
                          child: TransactionForm(state: state, cubit: cubit),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static PageRouteInfo _fallback(String? transactionId) => transactionId == null
      ? const TabsRoute(children: [TransactionsRoute()])
      : TransactionDetailRoute(transactionId: transactionId);
}
