import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/categories/categories.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class TransactionEditPage extends StatelessWidget {
  const TransactionEditPage({
    super.key,
    @PathParam('transactionId') required this.transactionId,
  });

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionFormCubit>()..init(transactionId),
      child: const TransactionEditView(),
    );
  }
}

/// Форма и создания, и правки: режим задаёт `TransactionFormState.transactionId`.
class TransactionEditView extends StatelessWidget {
  const TransactionEditView({super.key});

  static const _formMaxWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<TransactionFormCubit>();

    return BlocConsumer<TransactionFormCubit, TransactionFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case FormStatus.success:
            showAppToast(context, l10n.transactionFormSaved);
            navigateBack(context.router, _fallback(state.transactionId));
          case FormStatus.failure:
            if (state.failure case final failure?) {
              showAppToast(context, failureMessage(l10n, failure), error: true);
            }
          case FormStatus.idle || FormStatus.submitting:
            break;
        }
      },
      builder: (context, state) {
        final title = state.transactionId == null
            ? l10n.transactionFormNewTitle
            : l10n.transactionFormEditTitle;

        return AppGlassScaffold(
          leading: AppBackButton(fallback: _fallback(state.transactionId)),
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
                      onRetry: () => cubit.init(state.transactionId),
                    ),
                  ),
                )
              else if (state.isLoading || state.occurredAt == null)
                const SliverToBoxAdapter(
                  child: SkeletonList(itemCount: 5, itemHeight: 56),
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
                          child: _TransactionForm(state: state, cubit: cubit),
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

  static PageRouteInfo _fallback(String? transactionId) => transactionId == null
      ? const TabsRoute(children: [TransactionsRoute()])
      : TransactionDetailRoute(transactionId: transactionId);
}

class _TransactionForm extends StatelessWidget {
  const _TransactionForm({required this.state, required this.cubit});

  final TransactionFormState state;
  final TransactionFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final type = state.type;
    final isTransfer = type == TransactionType.transfer;
    String? error(TransactionField field) => switch (state.fieldErrors[field]) {
      final error? => fieldErrorText(l10n, error),
      null => null,
    };
    final occurredAt = state.occurredAt!;

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
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
            ButtonSegment(
              value: TransactionType.transfer,
              label: Text(l10n.transactionTypeTransfer),
            ),
          ],
          selected: {type},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => cubit.typeChanged(selection.first),
        ),
        TextFormField(
          initialValue: state.amount,
          onChanged: cubit.amountChanged,
          keyboardType: const .numberWithOptions(decimal: true),
          textAlign: .center,
          style: theme.textTheme.displaySmall,
          decoration: InputDecoration(
            labelText: l10n.transactionFormAmount,
            hintText: '0',
            suffixText: CurrencyScope.of(context).symbol,
            errorText: error(.amount),
          ),
        ),
        if (!isTransfer) ...[
          Text(
            l10n.transactionDetailCategory,
            style: theme.textTheme.titleSmall,
          ),
          CategoryPicker(
            kind: type == TransactionType.expense
                ? CategoryKind.expense
                : CategoryKind.income,
            selected: state.categoryId,
            onSelected: cubit.categoryChanged,
            errorText: error(.categoryId),
          ),
        ],
        AccountPicker(
          label: isTransfer
              ? l10n.transactionDetailFrom
              : l10n.transactionDetailAccount,
          selected: state.accountId,
          onSelected: cubit.accountChanged,
          errorText: error(.accountId),
        ),
        if (isTransfer)
          AccountPicker(
            label: l10n.transactionDetailTo,
            selected: state.toAccountId,
            onSelected: cubit.toAccountChanged,
            errorText: error(.toAccountId),
          ),
        InkWell(
          onTap: () => _pickDate(context, occurredAt),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.transactionFormDate,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(DateFormat.yMMMMd(locale).format(occurredAt)),
          ),
        ),
        TextFormField(
          initialValue: state.title,
          onChanged: cubit.titleChanged,
          textCapitalization: .sentences,
          decoration: InputDecoration(
            labelText: l10n.transactionFormTitle,
            hintText: l10n.transactionFormOptional,
          ),
        ),
        TextFormField(
          initialValue: state.note,
          onChanged: cubit.noteChanged,
          textCapitalization: .sentences,
          decoration: InputDecoration(
            labelText: l10n.transactionDetailNote,
            hintText: l10n.transactionFormOptional,
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

  Future<void> _pickDate(BuildContext context, DateTime current) async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: current.isAfter(now) ? now : current,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (day != null) cubit.dateChanged(day);
  }
}
