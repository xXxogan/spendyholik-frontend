import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/goals/presentation/cubit/goal_form_cubit.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class GoalEditPage extends StatelessWidget {
  const GoalEditPage({super.key, @PathParam('goalId') required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GoalFormCubit>()..init(goalId),
      child: const GoalEditView(),
    );
  }
}

/// Форма и создания, и правки: режим задаёт `GoalFormState.goalId`.
class GoalEditView extends StatelessWidget {
  const GoalEditView({super.key});

  static const _formMaxWidth = 560.0;
  static const _fallback = TabsRoute(children: [BudgetsRoute()]);
  static const _goalRoutes = {GoalDetailRoute.name, GoalEditRoute.name};

  /// Детали удалённой цели под формой показали бы «Не найдено» —
  /// снимаем их вместе с формой.
  static void _leaveDeleted(StackRouter router) {
    final hasParent = router.stackData.any(
      (route) => !_goalRoutes.contains(route.name),
    );
    if (hasParent) {
      router.popUntil((route) => !_goalRoutes.contains(route.settings.name));
    } else {
      router.replaceAll([_fallback]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<GoalFormCubit>();

    return BlocConsumer<GoalFormCubit, GoalFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.deleted != current.deleted,
      listener: (context, state) {
        if (state.deleted) {
          showAppToast(context, l10n.goalDeleted);
          _leaveDeleted(context.router);
          return;
        }
        switch (state.status) {
          case FormStatus.success:
            showAppToast(context, l10n.goalFormSaved);
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
        final title = state.goalId == null
            ? l10n.goalFormNewTitle
            : l10n.goalFormEditTitle;

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
                      onRetry: () => cubit.init(state.goalId!),
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
                          child: _GoalForm(state: state, cubit: cubit),
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

class _GoalForm extends StatelessWidget {
  const _GoalForm({required this.state, required this.cubit});

  final GoalFormState state;
  final GoalFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    String? error(GoalField field) => switch (state.fieldErrors[field]) {
      final error? => fieldErrorText(l10n, error),
      null => null,
    };
    final currencySymbol = CurrencyScope.of(context).symbol;
    final deadline = state.deadline;

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        TextFormField(
          initialValue: state.name,
          onChanged: cubit.nameChanged,
          textCapitalization: .sentences,
          decoration: InputDecoration(
            labelText: l10n.goalFormName,
            hintText: l10n.goalFormNameHint,
            errorText: error(.name),
          ),
        ),
        TextFormField(
          initialValue: state.target,
          onChanged: cubit.targetChanged,
          keyboardType: const .numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.goalFormTarget,
            hintText: '0',
            suffixText: currencySymbol,
            errorText: error(.target),
          ),
        ),
        if (state.goalId == null) ...[
          TextFormField(
            initialValue: state.initialContribution,
            onChanged: cubit.initialContributionChanged,
            keyboardType: const .numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.goalFormInitialContribution,
              hintText: '0',
              suffixText: currencySymbol,
              errorText: error(.initialContribution),
            ),
          ),
          AccountPicker(
            label: l10n.goalTopUpFrom,
            selected: state.initialAccountId,
            onSelected: cubit.initialAccountChanged,
            errorText: error(.initialAccountId),
          ),
        ],
        InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.goalFormDeadline,
            suffixIcon: deadline == null
                ? const Icon(Icons.event_outlined)
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.goalFormDeadlineClear,
                    onPressed: () => cubit.deadlineChanged(null),
                  ),
          ),
          child: InkWell(
            onTap: () => _pickDeadline(context),
            child: Text(
              deadline == null
                  ? l10n.goalFormNoDeadline
                  : DateFormat.yMMMMd(locale).format(deadline),
            ),
          ),
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
        if (state.goalId != null) _DeleteButton(state: state, cubit: cubit),
      ],
    );
  }

  Future<void> _pickDeadline(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = state.deadline;
    final picked = await showDatePicker(
      context: context,
      firstDate: current != null && current.isBefore(today) ? current : today,
      lastDate: DateTime(now.year + 30),
      initialDate: current ?? today,
    );
    if (picked != null) cubit.deadlineChanged(picked);
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.state, required this.cubit});

  final GoalFormState state;
  final GoalFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final negative = AppColors.negative(Theme.of(context).brightness);

    return OutlinedButton.icon(
      icon: const Icon(Icons.delete_outline),
      label: Text(l10n.goalDeleteAction),
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
                title: l10n.goalDeleteConfirmTitle,
                message: l10n.goalDeleteConfirmMessage,
                confirmLabel: l10n.goalDeleteAction,
                cancelLabel: l10n.commonCancel,
                destructive: true,
              );
              if (confirmed) await cubit.delete();
            },
    );
  }
}
