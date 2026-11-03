import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/features/budgets/presentation/cubit/budget_form_cubit.dart';
import 'package:spendyholik/features/budgets/presentation/widgets/widgets.dart';
import 'package:spendyholik/features/categories/categories.dart';
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
                          child: _BudgetForm(state: state, cubit: cubit),
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

class _BudgetForm extends StatelessWidget {
  const _BudgetForm({required this.state, required this.cubit});

  final BudgetFormState state;
  final BudgetFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    String? error(BudgetField field) => switch (state.fieldErrors[field]) {
      final error? => fieldErrorText(l10n, error),
      null => null,
    };
    final periodError = error(.period);

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        Text(l10n.budgetFormCategory, style: theme.textTheme.titleSmall),
        CategoryPicker(
          kind: CategoryKind.expense,
          selected: state.categoryId,
          onSelected: cubit.categoryChanged,
          errorText: error(.categoryId),
        ),
        TextFormField(
          initialValue: state.limit,
          onChanged: cubit.limitChanged,
          keyboardType: const .numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: switch (state.period) {
              BudgetPeriod.monthly => l10n.budgetFormLimitMonthly,
              BudgetPeriod.weekly => l10n.budgetFormLimitWeekly,
              BudgetPeriod.once => l10n.budgetFormLimit,
            },
            hintText: '0',
            suffixText: CurrencyScope.of(context).symbol,
            errorText: error(.limit),
          ),
        ),
        Text(l10n.budgetFormPeriod, style: theme.textTheme.titleSmall),
        BudgetPeriodChips(
          selected: state.period,
          onSelected: cubit.periodChanged,
        ),
        if (state.period == BudgetPeriod.once)
          Column(
            crossAxisAlignment: .start,
            spacing: 4,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range_outlined),
                label: Text(switch ((state.onceStart, state.onceEnd)) {
                  (final start?, final end?) => budgetRangeLabel(
                    locale,
                    start,
                    end,
                  ),
                  _ => l10n.budgetFormPickDates,
                }),
                onPressed: () => _pickRange(context),
              ),
              if (periodError != null)
                Text(
                  periodError,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: state.status == .submitting ? null : cubit.save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: state.status == .submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.commonSave),
        ),
        if (state.budgetId != null) _DeleteButton(state: state, cubit: cubit),
      ],
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showAppDateRangePicker(
      context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: switch ((state.onceStart, state.onceEnd)) {
        (final start?, final end?) => DateTimeRange(
          start: start,
          end: DateTime(end.year, end.month, end.day - 1),
        ),
        _ => null,
      },
    );
    if (range == null) return;
    final end = range.end;
    cubit.onceRangeChanged(
      range.start,
      DateTime(end.year, end.month, end.day + 1),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.state, required this.cubit});

  final BudgetFormState state;
  final BudgetFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final negative = AppColors.negative(Theme.of(context).brightness);

    return OutlinedButton.icon(
      icon: const Icon(Icons.delete_outline),
      label: Text(l10n.budgetDeleteAction),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: negative,
        side: BorderSide(color: negative),
      ),
      onPressed: state.status == .submitting
          ? null
          : () async {
              final confirmed = await showAppConfirmDialog(
                context,
                title: l10n.budgetDeleteConfirmTitle,
                message: l10n.budgetDeleteConfirmMessage,
                confirmLabel: l10n.budgetDeleteAction,
                cancelLabel: l10n.commonCancel,
                destructive: true,
              );
              if (confirmed) await cubit.delete();
            },
    );
  }
}
