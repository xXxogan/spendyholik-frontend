import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Политика обработки персональных данных. Пока заглушка: утверждённого текста
/// нет, публиковать приложение с ней нельзя (B-23).
@RoutePage()
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppGlassScaffold(
      leading: const AppBackButton(fallback: RegisterRoute()),
      title: l10n.privacyTitle,
      body: BaseLayout.slivers(
        largeTitle: l10n.privacyTitle,
        slivers: [
          ContentSliverPadding(
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const .only(top: 12),
                child: Text(l10n.privacyPlaceholder),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
