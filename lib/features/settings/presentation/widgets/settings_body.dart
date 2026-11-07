import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/settings/data/models/models.dart';
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

    return Column(
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
        const SettingsWipeButton(),
      ],
    );
  }
}
