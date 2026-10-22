import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/l10n/app_localizations.dart';

export 'package:spendyholik/l10n/app_localizations.dart';

export 'app_localizations_setup.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
