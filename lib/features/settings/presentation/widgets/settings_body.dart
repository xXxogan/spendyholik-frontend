import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/settings/data/models/models.dart';
import 'package:spendyholik/features/settings/presentation/cubit/notification_preferences_cubit.dart';
import 'package:spendyholik/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:spendyholik/features/settings/presentation/widgets/settings_card.dart';
import 'package:spendyholik/features/settings/presentation/widgets/settings_wipe_button.dart';
import 'package:spendyholik/l10n/l10n.dart';

class SettingsBody extends StatelessWidget {
  const SettingsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsCubit>();
    final state = settings.state;

    return BlocListener<
      NotificationPreferencesCubit,
      NotificationPreferencesState
    >(
      listenWhen: (_, current) =>
          current is NotificationPreferencesLoaded && current.failure != null,
      listener: (context, state) {
        if (state case NotificationPreferencesLoaded(:final failure?)) {
          showAppToast(context, failureMessage(l10n, failure), error: true);
        }
      },
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          SectionHeader(title: l10n.settingsAppearance),
          SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: Text(l10n.settingsTheme),
                subtitle: Padding(
                  padding: const .only(top: 12, bottom: 4),
                  child: SegmentedButton<AppThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: .system,
                        label: Text(l10n.settingsThemeSystem),
                      ),
                      ButtonSegment(
                        value: .light,
                        label: Text(l10n.settingsThemeLight),
                      ),
                      ButtonSegment(
                        value: .dark,
                        label: Text(l10n.settingsThemeDark),
                      ),
                    ],
                    selected: {state.themeMode},
                    onSelectionChanged: (selection) =>
                        settings.setThemeMode(selection.single),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.settingsNotifications),
          SettingsCard(
            children: [
              SwitchListTile(
                title: Text(l10n.settingsPush),
                subtitle: Text(l10n.settingsPushHint),
                value: state.pushEnabled,
                onChanged: settings.setPush,
              ),
              ..._serverSwitches(context),
            ],
          ),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.settingsData),
          const SettingsWipeButton(),
        ],
      ),
    );
  }

  /// Сервер создаёт эти уведомления сам, поэтому и выключаются они на сервере.
  List<Widget> _serverSwitches(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.watch<NotificationPreferencesCubit>();
    return switch (cubit.state) {
      NotificationPreferencesLoaded(:final preferences) => [
        for (final (kind, title, hint) in [
          (
            NotificationPreference.budget,
            l10n.settingsBudgetReminders,
            l10n.settingsBudgetRemindersHint,
          ),
          (
            NotificationPreference.goal,
            l10n.settingsGoalNotifications,
            l10n.settingsGoalNotificationsHint,
          ),
          (
            NotificationPreference.recurring,
            l10n.settingsRecurringNotifications,
            l10n.settingsRecurringNotificationsHint,
          ),
          (
            NotificationPreference.income,
            l10n.settingsIncomeNotifications,
            l10n.settingsIncomeNotificationsHint,
          ),
        ])
          SwitchListTile(
            title: Text(title),
            subtitle: Text(hint),
            value: preferences.of(kind),
            onChanged: (value) => cubit.toggle(kind, value),
          ),
      ],
      NotificationPreferencesError(:final failure) => [
        FailureView(failure: failure, onRetry: cubit.load),
      ],
      NotificationPreferencesLoading() => [
        const Padding(
          padding: .all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    };
  }
}
