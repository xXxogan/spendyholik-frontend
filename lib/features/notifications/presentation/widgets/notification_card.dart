import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/notifications/data/models/models.dart';
import 'package:spendyholik/features/notifications/presentation/widgets/notification_text.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.currency,
    this.onTap,
  });

  final NotificationModel notification;
  final Currency currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = !notification.isRead;
    final accent = theme.colorScheme.primary;
    final (title, details) = notificationText(context, notification, currency);

    return Card(
      margin: .zero,
      elevation: 0,
      clipBehavior: .antiAlias,
      color: unread
          ? Color.alphaBlend(
              accent.withValues(alpha: 0.08),
              theme.colorScheme.surface,
            )
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: unread ? accent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding: const .fromLTRB(16, 14, 16, 14),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    spacing: 4,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: unread ? .w700 : .w500,
                        ),
                      ),
                      Text(
                        details,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: accent, shape: .circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
