import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Разделы вне вкладок; тот же набор, что второй блок боковой панели.
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (Icons.category_outlined, l10n.categoriesTitle, const CategoriesRoute()),
      (
        Icons.event_repeat_outlined,
        l10n.recurringTitle,
        const RecurringRoute(),
      ),
      (Icons.handshake_outlined, l10n.debtsTitle, const DebtsRoute()),
      (
        Icons.notifications_outlined,
        l10n.notificationsTitle,
        const NotificationsRoute(),
      ),
    ];

    return Card(
      margin: .zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      clipBehavior: .antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(24)),
      child: Column(
        children: [
          for (final (i, (icon, title, route)) in items.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.router.push(route),
            ),
          ],
        ],
      ),
    );
  }
}
