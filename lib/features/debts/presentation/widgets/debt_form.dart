import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/debts/presentation/cubit/debt_form_cubit.dart';
import 'package:spendyholik/features/debts/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

class DebtForm extends StatelessWidget {
  const DebtForm({super.key, required this.state, required this.cubit});

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
    final currencySymbol =
        (state.accountCurrency ?? CurrencyScope.of(context)).symbol;
    final dueDate = state.dueDate;
    final openedOn = state.openedOn;
    final isCreate = state.debtId == null;

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
        if (isCreate) ...[
          AccountPicker(
            label: l10n.debtFormAccount,
            selected: state.accountId,
            onSelected: cubit.accountChanged,
            errorText: error(.accountId),
          ),
          // У выпадающего списка нет пункта «пусто» — сброс отдельной кнопкой.
          if (state.accountId != null)
            Align(
              alignment: .centerLeft,
              child: TextButton(
                onPressed: () => cubit.accountChanged(null),
                child: Text(l10n.debtFormNoAccount),
              ),
            ),
          InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.debtFormDate,
              suffixIcon: const Icon(Icons.event_outlined),
            ),
            child: InkWell(
              onTap: () => _pickOpenedOn(context),
              child: Text(
                openedOn == null
                    ? l10n.commonToday
                    : DateFormat.yMMMMd(locale).format(openedOn),
              ),
            ),
          ),
        ],
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

  Future<void> _pickOpenedOn(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: today,
      initialDate: state.openedOn ?? today,
    );
    if (picked != null) cubit.openedOnChanged(picked);
  }
}
