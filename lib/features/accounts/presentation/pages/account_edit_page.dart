import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/account_form_cubit.dart';
import 'package:spendyholik/features/accounts/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class AccountEditPage extends StatelessWidget {
  const AccountEditPage({
    super.key,
    @PathParam('accountId') required this.accountId,
  });

  final String accountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AccountFormCubit>()..init(accountId),
      child: const AccountEditView(),
    );
  }
}

/// Форма и создания, и правки: режим задаёт `AccountFormState.accountId`.
class AccountEditView extends StatelessWidget {
  const AccountEditView({super.key});

  static const _formMaxWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AccountFormCubit>();

    return BlocConsumer<AccountFormCubit, AccountFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case FormStatus.success:
            showAppToast(context, l10n.accountFormSaved);
            navigateBack(context.router, _fallback(state.accountId));
          case FormStatus.failure:
            if (state.failure case final failure?) {
              showAppToast(context, failureMessage(l10n, failure), error: true);
            }
          case FormStatus.idle || FormStatus.submitting:
            break;
        }
      },
      builder: (context, state) {
        final title = state.accountId == null
            ? l10n.accountFormNewTitle
            : l10n.accountFormEditTitle;

        return AppGlassScaffold(
          leading: AppBackButton(fallback: _fallback(state.accountId)),
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
                      onRetry: () => cubit.init(state.accountId),
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
                          child: _AccountForm(state: state, cubit: cubit),
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

  static PageRouteInfo _fallback(String? accountId) => accountId == null
      ? const AccountsRoute()
      : AccountDetailRoute(accountId: accountId);
}

class _AccountForm extends StatelessWidget {
  const _AccountForm({required this.state, required this.cubit});

  final AccountFormState state;
  final AccountFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labelStyle = Theme.of(context).textTheme.titleSmall;
    final type = state.type;
    String? error(AccountField field) => switch (state.fieldErrors[field]) {
      final error? => fieldErrorText(l10n, error),
      null => null,
    };
    const amountKeyboard = TextInputType.numberWithOptions(decimal: true);

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        TextFormField(
          initialValue: state.name,
          onChanged: cubit.nameChanged,
          textCapitalization: .sentences,
          decoration: InputDecoration(
            labelText: l10n.accountFormName,
            hintText: l10n.accountFormNameHint,
            errorText: error(.name),
          ),
        ),
        Text(l10n.accountFormType, style: labelStyle),
        AccountTypeChips(selected: type, onSelected: cubit.typeChanged),
        TextFormField(
          initialValue: state.balance,
          onChanged: cubit.balanceChanged,
          keyboardType: const .numberWithOptions(signed: true, decimal: true),
          decoration: InputDecoration(
            labelText: state.accountId == null
                ? l10n.accountFormInitialBalance
                : l10n.accountDetailCurrentBalance,
            hintText: '0',
            errorText: error(.balance),
          ),
        ),
        if (type == .debit || type == .credit)
          TextFormField(
            initialValue: state.cardLast4,
            onChanged: cubit.cardLast4Changed,
            keyboardType: .number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              labelText: l10n.accountFormCardLast4,
              errorText: error(.cardLast4),
            ),
          ),
        if (type == .savings)
          TextFormField(
            initialValue: state.interestRate,
            onChanged: cubit.interestRateChanged,
            keyboardType: amountKeyboard,
            decoration: InputDecoration(
              labelText: l10n.accountFormInterestRate,
              errorText: error(.interestRate),
            ),
          ),
        if (type == .credit)
          TextFormField(
            initialValue: state.creditLimit,
            onChanged: cubit.creditLimitChanged,
            keyboardType: amountKeyboard,
            decoration: InputDecoration(
              labelText: l10n.accountFormCreditLimit,
              errorText: error(.creditLimit),
            ),
          ),
        Text(l10n.accountFormColor, style: labelStyle),
        ColorSwatchPicker(
          selected: state.color,
          onSelected: cubit.colorChanged,
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
}
