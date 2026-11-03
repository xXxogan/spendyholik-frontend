import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

// Сам Профиль — в своей задаче; пока здесь только вход в разделы вне вкладок.
@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      largeTitle: context.l10n.navProfile,
      children: [
        Padding(
          padding: const .symmetric(horizontal: 16, vertical: 12),
          child: Card(
            margin: .zero,
            elevation: 0,
            color: Theme.of(context).colorScheme.surface,
            clipBehavior: .antiAlias,
            shape: RoundedRectangleBorder(borderRadius: .circular(24)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(context.l10n.categoriesTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.router.push(const CategoriesRoute()),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.event_repeat_outlined),
                  title: Text(context.l10n.recurringTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.router.push(const RecurringRoute()),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.handshake_outlined),
                  title: Text(context.l10n.debtsTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.router.push(const DebtsRoute()),
                ),
              ],
            ),
          ),
        ),
        const SkeletonList(itemCount: 10),
      ],
    );
  }
}
