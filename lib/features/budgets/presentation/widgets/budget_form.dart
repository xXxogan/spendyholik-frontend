import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/features/budgets/presentation/cubit/budget_form_cubit.dart';
import 'package:spendyholik/features/budgets/presentation/widgets/widgets.dart';
import 'package:spendyholik/features/categories/categories.dart';
import 'package:spendyholik/l10n/l10n.dart';

class BudgetForm extends StatelessWidget {
  const BudgetForm({super.key, required this.state, required this.cubit});

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
        if (state.budgetId != null)
          BudgetDeleteButton(state: state, cubit: cubit),
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
