import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/categories/categories.dart';
import 'package:spendyholik/features/recurring/presentation/cubit/recurring_form_cubit.dart';
import 'package:spendyholik/features/recurring/presentation/widgets/widgets.dart';
import 'package:spendyholik/features/transactions/transactions.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class RecurringEditPage extends StatelessWidget {
  const RecurringEditPage({
    super.key,
    @PathParam('recurringId') required this.recurringId,
  });

  final String recurringId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RecurringFormCubit>()..init(recurringId),
      child: const RecurringEditView(),
    );
  }
}

/// Форма и создания, и правки: режим задаёт `RecurringFormState.recurringId`.
class RecurringEditView extends StatelessWidget {
  const RecurringEditView({super.key});

  static const _formMaxWidth = 560.0;
  static const _fallback = RecurringRoute();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<RecurringFormCubit>();

    return BlocConsumer<RecurringFormCubit, RecurringFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case FormStatus.success:
            showAppToast(context, l10n.recurringFormSaved);
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
        final title = state.recurringId == null
            ? l10n.recurringFormNewTitle
            : l10n.recurringFormEditTitle;

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
                      onRetry: () => cubit.init(state.recurringId!),
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
                          child: _RecurringForm(state: state, cubit: cubit),
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

class _RecurringForm extends StatelessWidget {
  const _RecurringForm({required this.state, required this.cubit});

  final RecurringFormState state;
  final RecurringFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final anchor = state.anchor;
    final next = state.nextExecution(now);
    String? error(RecurringField field) => switch (state.fieldErrors[field]) {
      final error? => fieldErrorText(l10n, error),
      null => null,
    };

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        TextFormField(
          initialValue: state.title,
          onChanged: cubit.titleChanged,
          textCapitalization: .sentences,
          decoration: InputDecoration(
            labelText: l10n.recurringFormName,
            hintText: l10n.recurringFormNameHint,
            errorText: error(.title),
          ),
        ),
        TextFormField(
          initialValue: state.amount,
          onChanged: cubit.amountChanged,
          keyboardType: const .numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.recurringFormAmount,
            hintText: '0',
            suffixText: CurrencyScope.of(context).symbol,
            errorText: error(.amount),
          ),
        ),
        SegmentedButton<TransactionType>(
          segments: [
            ButtonSegment(
              value: TransactionType.expense,
              label: Text(l10n.transactionTypeExpense),
            ),
            ButtonSegment(
              value: TransactionType.income,
              label: Text(l10n.transactionTypeIncome),
            ),
          ],
          selected: {state.type},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => cubit.typeChanged(selection.first),
        ),
        Text(l10n.recurringFormCategory, style: theme.textTheme.titleSmall),
        CategoryPicker(
          kind: state.type == TransactionType.expense
              ? CategoryKind.expense
              : CategoryKind.income,
          selected: state.categoryId,
          onSelected: cubit.categoryChanged,
          errorText: error(.categoryId),
        ),
        AccountPicker(
          label: l10n.recurringFormAccount,
          selected: state.accountId,
          onSelected: cubit.accountChanged,
          errorText: error(.accountId),
        ),
        Text(l10n.recurringFormFrequency, style: theme.textTheme.titleSmall),
        RecurringFrequencyChips(
          selected: state.frequency,
          onSelected: cubit.frequencyChanged,
        ),
        InkWell(
          onTap: anchor == null ? null : () => _pickAnchor(context, anchor),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.recurringFormAnchor,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              anchor == null ? '' : DateFormat.yMMMMd(locale).format(anchor),
            ),
          ),
        ),
        if (next != null)
          Text(
            l10n.recurringFormNextExecution(
              formatDayLabel(next, now, l10n, locale),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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

  Future<void> _pickAnchor(BuildContext context, DateTime current) async {
    final now = DateTime.now();
    final first = DateTime(now.year - 1, now.month, now.day);
    final last = DateTime(now.year + 5, now.month, now.day);
    final day = await showDatePicker(
      context: context,
      // Правка старого шаблона: якорь может быть раньше окна выбора.
      initialDate: current.isBefore(first) ? first : current,
      firstDate: first,
      lastDate: last,
    );
    if (day != null) cubit.anchorChanged(day);
  }
}
