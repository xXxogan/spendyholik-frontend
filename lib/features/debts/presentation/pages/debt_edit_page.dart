import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/debts/presentation/cubit/debt_form_cubit.dart';
import 'package:spendyholik/features/debts/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class DebtEditPage extends StatelessWidget {
  const DebtEditPage({super.key, @PathParam('debtId') required this.debtId});

  final String debtId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DebtFormCubit>()..init(debtId),
      child: const DebtEditView(),
    );
  }
}

/// Форма и создания, и правки: режим задаёт `DebtFormState.debtId`.
class DebtEditView extends StatelessWidget {
  const DebtEditView({super.key});

  static const _formMaxWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<DebtFormCubit>();

    return BlocConsumer<DebtFormCubit, DebtFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case FormStatus.success:
            showAppToast(context, l10n.debtFormSaved);
            navigateBack(context.router, const DebtsRoute());
          case FormStatus.failure:
            if (state.failure case final failure?) {
              showAppToast(context, failureMessage(l10n, failure), error: true);
            }
          case FormStatus.idle || FormStatus.submitting:
            break;
        }
      },
      builder: (context, state) {
        final title = state.debtId == null
            ? l10n.debtFormNewTitle
            : l10n.debtFormEditTitle;

        return AppGlassScaffold(
          leading: const AppBackButton(fallback: DebtsRoute()),
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
                      onRetry: () => cubit.init(state.debtId!),
                    ),
                  ),
                )
              else if (state.isLoading)
                const SliverToBoxAdapter(
                  child: SkeletonList(itemCount: 4, itemHeight: 56),
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
                          child: DebtForm(state: state, cubit: cubit),
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
}
