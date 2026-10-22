import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transaction_filters_cubit.dart';
import 'package:spendyholik/features/transactions/presentation/widgets/transaction_type_chips.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Возвращает выбранный фильтр по «Применить», null — если шторку закрыли.
Future<TransactionFilter?> showTransactionFiltersSheet(
  BuildContext context,
  TransactionFilter current,
) => showGlassSheet<TransactionFilter>(
  context,
  builder: (_) => BlocProvider(
    create: (_) => getIt<TransactionFiltersCubit>()..init(current),
    child: const TransactionFiltersView(),
  ),
);

class TransactionFiltersView extends StatelessWidget {
  const TransactionFiltersView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<TransactionFiltersCubit>();
    final state = context.watch<TransactionFiltersCubit>().state;
    final filter = state.filter;

    Widget section(String label, Widget child) => Padding(
      padding: const .only(bottom: 16),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 8,
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          child,
        ],
      ),
    );

    Widget chips<T>(
      Map<T?, String> options,
      T? selected,
      ValueChanged<T?> onSelected,
    ) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final MapEntry(key: value, value: label) in options.entries)
          ChoiceChip(
            label: Text(label),
            selected: value == selected,
            onSelected: (_) => onSelected(value),
          ),
      ],
    );

    final body = switch (state) {
      TransactionFiltersState(isLoading: true) => const Padding(
        padding: .symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      TransactionFiltersState(:final failure?) => FailureView(
        failure: failure,
        onRetry: () => cubit.init(filter),
      ),
      _ => Column(
        crossAxisAlignment: .stretch,
        children: [
          section(
            l10n.transactionFiltersPeriod,
            chips<PeriodPreset>(
              {
                null: l10n.transactionFiltersAllTime,
                PeriodPreset.week: l10n.periodWeek,
                PeriodPreset.month: l10n.periodMonth,
                PeriodPreset.year: l10n.periodYear,
                PeriodPreset.custom: _customLabel(context, state),
              },
              state.preset,
              (preset) => preset == PeriodPreset.custom
                  ? _pickCustom(context, cubit, filter.period)
                  : cubit.setPeriod(preset),
            ),
          ),
          section(
            l10n.transactionFiltersType,
            TransactionTypeChips(
              selected: filter.type,
              onSelected: cubit.setType,
            ),
          ),
          if (state.categoryOptions.isNotEmpty)
            section(
              l10n.transactionFiltersCategory,
              chips<String>(
                {
                  null: l10n.transactionFiltersAny,
                  for (final category in state.categoryOptions)
                    category.id: category.name,
                },
                filter.categoryId,
                cubit.setCategory,
              ),
            ),
          section(
            l10n.transactionFiltersAccount,
            chips<String>(
              {
                null: l10n.transactionFiltersAny,
                for (final account in state.accounts) account.id: account.name,
              },
              filter.accountId,
              cubit.setAccount,
            ),
          ),
          const SizedBox(height: 4),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(filter),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(l10n.transactionFiltersApply),
          ),
        ],
      ),
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.transactionFiltersTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: cubit.reset,
                child: Text(l10n.transactionsReset),
              ),
            ],
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  String _customLabel(BuildContext context, TransactionFiltersState state) {
    final period = state.filter.period;
    if (state.preset != PeriodPreset.custom || period == null) {
      return context.l10n.periodCustom;
    }
    final format = DateFormat.MMMd(Localizations.localeOf(context).toString());
    final end = period.end;
    final lastDay = DateTime(end.year, end.month, end.day - 1);
    return '${format.format(period.start)} – ${format.format(lastDay)}';
  }

  Future<void> _pickCustom(
    BuildContext context,
    TransactionFiltersCubit cubit,
    DatePeriod? current,
  ) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 10);
    final lastDate = DateTime(now.year, now.month, now.day);
    final range = await showAppDateRangePicker(
      context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: pickerRangeFor(current, firstDate, lastDate),
    );
    if (range == null) return;
    final end = range.end;
    cubit.setPeriod(
      .custom,
      custom: DatePeriod(
        start: range.start,
        end: DateTime(end.year, end.month, end.day + 1),
      ),
    );
  }
}

/// Начальный диапазон календаря в его границах: пресет «Месяц» тянется до
/// конца месяца, а showDateRangePicker падает, если конец позже [last].
DateTimeRange? pickerRangeFor(
  DatePeriod? period,
  DateTime first,
  DateTime last,
) {
  if (period == null) return null;
  DateTime clamp(DateTime day) =>
      day.isBefore(first) ? first : (day.isAfter(last) ? last : day);
  final end = period.end;
  return DateTimeRange(
    start: clamp(period.start),
    end: clamp(DateTime(end.year, end.month, end.day - 1)),
  );
}
