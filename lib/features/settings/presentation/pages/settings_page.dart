import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/settings/presentation/cubit/data_reset_cubit.dart';
import 'package:spendyholik/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _maxWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = l10n.settingsTitle;

    return BlocProvider(
      create: (_) => getIt<DataResetCubit>(),
      child: BlocListener<DataResetCubit, DataResetState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          switch (state.status) {
            case .success:
              showAppToast(context, l10n.settingsWiped);
            case .failure:
              if (state.failure case final failure?) {
                showAppToast(
                  context,
                  failureMessage(l10n, failure),
                  error: true,
                );
              }
            case .idle || .submitting:
          }
        },
        child: AppGlassScaffold(
          leading: const AppBackButton(
            fallback: TabsRoute(children: [ProfileRoute()]),
          ),
          title: title,
          largeTitle: true,
          body: BaseLayout.slivers(
            largeTitle: title,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ContentSliverPadding(
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _maxWidth),
                      child: const _SettingsBody(),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsCubit>();
    final state = settings.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(title: l10n.settingsAppearance),
        _SettingsCard(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: Text(l10n.settingsDarkTheme),
              value: isDark,
              onChanged: settings.setDarkTheme,
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionHeader(title: l10n.settingsNotifications),
        _SettingsCard(
          children: [
            SwitchListTile(
              title: Text(l10n.settingsPush),
              subtitle: Text(l10n.settingsPushHint),
              value: state.pushEnabled,
              onChanged: settings.setPush,
            ),
            SwitchListTile(
              title: Text(l10n.settingsBudgetReminders),
              subtitle: Text(l10n.settingsBudgetRemindersHint),
              value: state.budgetReminders,
              onChanged: settings.setBudgetReminders,
            ),
            SwitchListTile(
              title: Text(l10n.settingsWeeklyReport),
              subtitle: Text(l10n.settingsWeeklyReportHint),
              value: state.weeklyReport,
              onChanged: settings.setWeeklyReport,
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionHeader(title: l10n.settingsData),
        const _WipeButton(),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: .zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      clipBehavior: .antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(24)),
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            child,
          ],
        ],
      ),
    );
  }
}

class _WipeButton extends StatelessWidget {
  const _WipeButton();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final negative = AppColors.negative(Theme.of(context).brightness);
    final submitting =
        context.watch<DataResetCubit>().state.status == FormStatus.submitting;

    return OutlinedButton.icon(
      icon: const Icon(Icons.delete_outline),
      label: Text(l10n.settingsWipe),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: negative,
        side: BorderSide(color: negative),
      ),
      onPressed: submitting
          ? null
          : () async {
              final cubit = context.read<DataResetCubit>();
              final confirmed = await showAppConfirmDialog(
                context,
                title: l10n.settingsWipeConfirmTitle,
                message: l10n.settingsWipeConfirmMessage,
                confirmLabel: l10n.settingsWipeConfirm,
                cancelLabel: l10n.commonCancel,
                destructive: true,
              );
              if (confirmed) await cubit.wipe();
            },
    );
  }
}
