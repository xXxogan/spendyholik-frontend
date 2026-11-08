import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/format/format.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';
import 'package:spendyholik/features/debts/presentation/cubit/debt_repay_cubit.dart';
import 'package:spendyholik/l10n/l10n.dart';

Future<void> showDebtRepaySheet(BuildContext context, DebtModel debt) async {
  final done = await showGlassSheet<bool>(
    context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<DebtRepayCubit>()..init(debt),
      child: DebtRepayView(
        counterparty: debt.counterparty,
        currency: debt.currency,
      ),
    ),
  );
  if (done == true && context.mounted) {
    showAppToast(context, context.l10n.debtRepayDone);
  }
}

class DebtRepayView extends StatefulWidget {
  const DebtRepayView({
    super.key,
    required this.counterparty,
    required this.currency,
  });

  final String counterparty;

  /// Погашение — в валюте долга.
  final Currency currency;

  @override
  State<DebtRepayView> createState() => _DebtRepayViewState();
}

class _DebtRepayViewState extends State<DebtRepayView> {
  // «Полностью» и «Половина» меняют сумму из Cubit — поле должно это показать.
  late final _amount = TextEditingController(
    text: context.read<DebtRepayCubit>().state.amount,
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final cubit = context.read<DebtRepayCubit>();

    return BlocConsumer<DebtRepayCubit, DebtRepayState>(
      listener: (context, state) {
        if (state.status == FormStatus.success) {
          Navigator.of(context).pop(true);
        }
        if (_amount.text != state.amount) _amount.text = state.amount;
      },
      builder: (context, state) {
        String? error(RepayField field) => switch (state.fieldErrors[field]) {
          final error? => fieldErrorText(l10n, error),
          null => null,
        };
        final currency = widget.currency;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: 16,
            children: [
              Column(
                crossAxisAlignment: .start,
                children: [
                  Text(l10n.debtRepayTitle, style: theme.textTheme.titleLarge),
                  Text(
                    l10n.debtRepaySubtitle(
                      widget.counterparty,
                      formatMoney(state.remaining, currency, locale),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _amount,
                onChanged: cubit.amountChanged,
                keyboardType: const .numberWithOptions(decimal: true),
                textAlign: .center,
                style: theme.textTheme.headlineMedium,
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: currency.symbol,
                  errorText: error(.amount),
                ),
              ),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: cubit.setFull,
                      child: Text(l10n.debtRepayFull),
                    ),
                  ),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: cubit.setHalf,
                      child: Text(l10n.debtRepayHalf),
                    ),
                  ),
                ],
              ),
              AccountPicker(
                label: l10n.debtRepayAccount,
                selected: state.accountId,
                onSelected: cubit.accountChanged,
                errorText: error(.accountId),
              ),
              if (state.status == FormStatus.failure)
                if (state.failure case final failure?)
                  Text(
                    failureMessage(l10n, failure),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
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
                    : Text(l10n.debtRepaySubmit),
              ),
            ],
          ),
        );
      },
    );
  }
}
