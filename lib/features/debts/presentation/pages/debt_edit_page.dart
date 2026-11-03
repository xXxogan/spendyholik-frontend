import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
                          child: _DebtForm(state: state, cubit: cubit),
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

class _DebtForm extends StatelessWidget {
  const _DebtForm({required this.state, required this.cubit});

  final DebtFormState state;
  final DebtFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    String? error(DebtField field) => switch (state.fieldErrors[field]) {
      final error? => fieldErrorText(l10n, error),
      null => null,
    };
    // Базовая валюта придёт из SessionCubit вместе с фичей user (T-28).
    final currencySymbol = Currency.rub.symbol;
    final dueDate = state.dueDate;

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        TextFormField(
          initialValue: state.counterparty,
          onChanged: cubit.counterpartyChanged,
          textCapitalization: .words,
          decoration: InputDecoration(
            labelText: l10n.debtFormCounterparty,
            hintText: l10n.debtFormCounterpartyHint,
            errorText: error(.counterparty),
          ),
        ),
        DebtsDirectionSegment(
          selected: state.direction,
          onSelected: state.debtId == null ? cubit.directionChanged : null,
        ),
        TextFormField(
          initialValue: state.amount,
          onChanged: cubit.amountChanged,
          keyboardType: const .numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.debtFormAmount,
            hintText: '0',
            suffixText: currencySymbol,
            errorText: error(.amount),
          ),
        ),
        InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.debtFormDueDate,
            suffixIcon: dueDate == null
                ? const Icon(Icons.event_outlined)
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.debtFormDueDateClear,
                    onPressed: () => cubit.dueDateChanged(null),
                  ),
          ),
          child: InkWell(
            onTap: () => _pickDueDate(context),
            child: Text(
              dueDate == null
                  ? l10n.debtFormNoDueDate
                  : DateFormat.yMMMMd(locale).format(dueDate),
            ),
          ),
        ),
        TextFormField(
          initialValue: state.note,
          onChanged: cubit.noteChanged,
          textCapitalization: .sentences,
          decoration: InputDecoration(
            labelText: l10n.debtFormNote,
            hintText: l10n.debtFormNoteHint,
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
      ],
    );
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = state.dueDate;
    final picked = await showDatePicker(
      context: context,
      firstDate: current != null && current.isBefore(today) ? current : today,
      lastDate: DateTime(now.year + 10),
      initialDate: current ?? today,
    );
    if (picked != null) cubit.dueDateChanged(picked);
  }
}
