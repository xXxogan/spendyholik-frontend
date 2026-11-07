import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/goals/presentation/cubit/goal_form_cubit.dart';
import 'package:spendyholik/features/goals/presentation/widgets/goal_delete_button.dart';
import 'package:spendyholik/l10n/l10n.dart';

class GoalForm extends StatelessWidget {
  const GoalForm({super.key, required this.state, required this.cubit});

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
        if (state.goalId != null) GoalDeleteButton(state: state, cubit: cubit),
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
