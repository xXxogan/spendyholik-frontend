import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/categories/categories.dart';
import 'package:spendyholik/features/recurring/presentation/cubit/recurring_form_cubit.dart';
import 'package:spendyholik/features/recurring/presentation/widgets/widgets.dart';
import 'package:spendyholik/features/transactions/transactions.dart';
import 'package:spendyholik/l10n/l10n.dart';

class RecurringForm extends StatelessWidget {
  const RecurringForm({super.key, required this.state, required this.cubit});

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
            suffixText:
                (state.accountCurrency ?? CurrencyScope.of(context)).symbol,
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
          // В правке тип зафиксирован (см. RecurringFormCubit.typeChanged).
          onSelectionChanged: state.recurringId == null
              ? (selection) => cubit.typeChanged(selection.first)
              : null,
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
