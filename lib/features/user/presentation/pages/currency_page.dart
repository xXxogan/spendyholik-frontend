import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/user/presentation/cubit/currency_cubit.dart';
import 'package:spendyholik/features/user/presentation/cubit/session_cubit.dart';
import 'package:spendyholik/features/user/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class CurrencyPage extends StatelessWidget {
  const CurrencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = getIt<SessionCubit>().state;
    return BlocProvider(
      create: (_) => getIt<CurrencyCubit>()
        ..init(switch (session) {
          SessionAuthenticated(:final user) => user.baseCurrency,
          _ => null,
        }),
      child: const CurrencyView(),
    );
  }
}

class CurrencyView extends StatelessWidget {
  const CurrencyView({super.key});

  static const _maxWidth = 560.0;

  /// Пользователь с новой валютой приходит в сессию через userChanges, а не
  /// вместе с ответом: без ожидания guard Главной вернёт сюда же.
  static Future<void> _goHome(BuildContext context) async {
    final session = getIt<SessionCubit>();
    bool hasCurrency(SessionState s) =>
        s is SessionAuthenticated && s.user.baseCurrency != null;
    if (!hasCurrency(session.state)) {
      await session.stream.firstWhere(hasCurrency);
    }
    if (context.mounted) await context.router.replaceAll([const HomeRoute()]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<CurrencyCubit>();

    return BlocConsumer<CurrencyCubit, CurrencyState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case FormStatus.success:
            _goHome(context);
          case FormStatus.failure:
            if (state.failure case final failure?) {
              showAppToast(context, failureMessage(l10n, failure), error: true);
            }
          case FormStatus.idle || FormStatus.submitting:
            break;
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(l10n.userCurrencyTitle)),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  Padding(
                    padding: const .fromLTRB(16, 8, 16, 8),
                    child: Text(
                      l10n.currencyHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final currency in Currency.values)
                          ListTile(
                            leading: SizedBox(
                              width: 48,
                              child: Text(
                                currency.code,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            title: Text(
                              '${currencyLabel(l10n, currency)} · '
                              '${currency.symbol}',
                            ),
                            trailing: Icon(
                              currency == state.selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: currency == state.selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                            onTap: () => cubit.select(currency),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const .all(16),
                    child: FilledButton(
                      onPressed: state.status == .submitting
                          ? null
                          : cubit.submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: state.status == .submitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.currencyContinue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
