import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/goals/presentation/cubit/goal_top_up_cubit.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Пополнение — в валюте цели.
Future<void> showGoalTopUpSheet(
  BuildContext context,
  String goalId,
  Currency currency,
) async {
  final done = await showGlassSheet<bool>(
    context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<GoalTopUpCubit>()..init(goalId),
      child: GoalTopUpView(currency: currency),
    ),
  );
  if (done == true && context.mounted) {
    showAppToast(context, context.l10n.goalTopUpDone);
  }
}

class GoalTopUpView extends StatelessWidget {
  const GoalTopUpView({super.key, required this.currency});

  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<GoalTopUpCubit>();

    return BlocConsumer<GoalTopUpCubit, GoalTopUpState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == FormStatus.success) Navigator.of(context).pop(true);
      },
      builder: (context, state) {
        String? error(TopUpField field) => switch (state.fieldErrors[field]) {
          final error? => fieldErrorText(l10n, error),
          null => null,
        };

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: 16,
            children: [
              Text(l10n.goalTopUpTitle, style: theme.textTheme.titleLarge),
              TextField(
                autofocus: true,
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
              AccountPicker(
                label: l10n.goalTopUpFrom,
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
                    : Text(l10n.goalTopUpSubmit),
              ),
            ],
          ),
        );
      },
    );
  }
}
