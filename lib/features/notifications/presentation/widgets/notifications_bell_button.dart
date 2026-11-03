import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/notifications/presentation/cubit/unread_count_cubit.dart';
import 'package:spendyholik/l10n/l10n.dart';

/// Колокольчик в шапке Главной со счётчиком непрочитанных.
class NotificationsBellButton extends StatelessWidget {
  const NotificationsBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UnreadCountCubit>()..load(),
      child: BlocBuilder<UnreadCountCubit, int>(
        builder: (context, count) => Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          child: AppGlassIconButton(
            icon: count > 0
                ? Icons.notifications
                : Icons.notifications_outlined,
            tooltip: context.l10n.notificationsTitle,
            onPressed: () => context.router.push(const NotificationsRoute()),
          ),
        ),
      ),
    );
  }
}
