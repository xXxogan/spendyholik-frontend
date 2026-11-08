import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/quick_add_cubit.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Шторка «Быстрое добавление»; тост — на странице-вызывающей, когда шторка
/// уже закрыта: так он встаёт правее боковой панели.
Future<void> showQuickAddSheet(BuildContext context) async {
  final added = await showGlassSheet<bool>(
    context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<QuickAddCubit>()..init(),
      child: const QuickAddView(),
    ),
  );
  if (added == true && context.mounted) {
    showAppToast(context, context.l10n.quickAddDone);
  }
}

class QuickAddView extends StatelessWidget {
  const QuickAddView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<QuickAddCubit>();

    return BlocConsumer<QuickAddCubit, QuickAddState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == FormStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        String? error(QuickAddField field) =>
            switch (state.fieldErrors[field]) {
              final error? => fieldErrorText(l10n, error),
              null => null,
            };
        final errorStyle = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        );

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: 16,
            children: [
              Text(l10n.quickAddTitle, style: theme.textTheme.titleLarge),
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
                onSelectionChanged: (selection) =>
                    cubit.typeChanged(selection.first),
              ),
              TextField(
                autofocus: true,
                onChanged: cubit.amountChanged,
                keyboardType: const .numberWithOptions(decimal: true),
                textAlign: .center,
                style: theme.textTheme.headlineMedium,
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText:
                      (state.accountCurrency ?? CurrencyScope.of(context))
                          .symbol,
                  errorText: error(.amount),
                ),
              ),
              Text(
                l10n.transactionDetailCategory,
                style: theme.textTheme.titleSmall,
              ),
              if (state.isLoading)
                const SkeletonList(itemCount: 1, itemHeight: 40)
              else if (state.failure case final failure?
                  when state.status != FormStatus.failure)
                FailureView(failure: failure, onRetry: cubit.init)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in state.categories)
                      ChoiceChip(
                        label: Text(category.name),
                        selected: category.id == state.categoryId,
                        onSelected: (_) => cubit.categoryChanged(category.id),
                      ),
                  ],
                ),
              if (error(.category) case final text?)
                Text(text, style: errorStyle),
              if (state.fieldErrors.containsKey(QuickAddField.account))
                Text(l10n.quickAddNoDebit, style: errorStyle),
              if (state.status == FormStatus.failure)
                if (state.failure case final failure?)
                  Text(failureMessage(l10n, failure), style: errorStyle),
              FilledButton(
                onPressed: state.status == .submitting ? null : cubit.submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: state.status == .submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.quickAddSubmit),
              ),
            ],
          ),
        );
      },
    );
  }
}
