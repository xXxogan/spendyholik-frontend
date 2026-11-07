import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/budgets/presentation/cubit/budget_form_cubit.dart';
import 'package:spendyholik/features/budgets/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class BudgetEditPage extends StatelessWidget {
  const BudgetEditPage({
    super.key,
    @PathParam('budgetId') required this.budgetId,
  });

  final String budgetId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BudgetFormCubit>()..init(budgetId),
      child: const BudgetEditView(),
    );
  }
}

/// Форма и создания, и правки: режим задаёт `BudgetFormState.budgetId`.
class BudgetEditView extends StatelessWidget {
  const BudgetEditView({super.key});

  static const _formMaxWidth = 560.0;
  static const _fallback = TabsRoute(children: [BudgetsRoute()]);
  static const _budgetRoutes = {BudgetDetailRoute.name, BudgetEditRoute.name};

  /// Детали удалённого бюджета под формой показали бы «Не найдено» —
  /// снимаем их вместе с формой.
  static void _leaveDeleted(StackRouter router) {
    final hasParent = router.stackData.any(
      (route) => !_budgetRoutes.contains(route.name),
    );
    if (hasParent) {
      router.popUntil((route) => !_budgetRoutes.contains(route.settings.name));
    } else {
      router.replaceAll([_fallback]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<BudgetFormCubit>();

    return BlocConsumer<BudgetFormCubit, BudgetFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.deleted != current.deleted,
      listener: (context, state) {
        if (state.deleted) {
          showAppToast(context, l10n.budgetDeleted);
          _leaveDeleted(context.router);
          return;
        }
        switch (state.status) {
          case FormStatus.success:
            showAppToast(context, l10n.budgetFormSaved);
            navigateBack(context.router, _fallback);
          case FormStatus.failure:
            if (state.failure case final failure?) {
              showAppToast(context, failureMessage(l10n, failure), error: true);
            }
          case FormStatus.idle || FormStatus.submitting:
            break;
        }
      },
      builder: (context, state) {
        final title = state.budgetId == null
            ? l10n.budgetFormNewTitle
            : l10n.budgetFormEditTitle;

        return AppGlassScaffold(
          leading: const AppBackButton(fallback: _fallback),
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
                      onRetry: () => cubit.init(state.budgetId!),
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
                          child: BudgetForm(state: state, cubit: cubit),
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
