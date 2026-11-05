import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/config/app_config.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _maxWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = l10n.aboutTitle;

    return AppGlassScaffold(
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
                  child: Column(
                    spacing: 12,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: .circular(22),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          size: 36,
                          color: scheme.onPrimary,
                        ),
                      ),
                      Text(
                        l10n.appTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: .bold,
                        ),
                      ),
                      Text(
                        l10n.aboutVersion(AppConfig.appVersion),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ContentCard(
                        child: Column(
                          spacing: 12,
                          children: [
                            _InfoRow(
                              label: l10n.aboutVersionLabel,
                              value: AppConfig.appVersion,
                            ),
                            _InfoRow(
                              label: l10n.aboutData,
                              value: l10n.aboutDataValue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: .start,
      spacing: 16,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: .end,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
