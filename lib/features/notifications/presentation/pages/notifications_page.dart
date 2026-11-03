import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:spendyholik/features/notifications/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NotificationsCubit>()..load(),
      child: const NotificationsView(),
    );
  }
}

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  // Базовая валюта придёт из SessionCubit вместе с фичей user (T-28).
  static const _currency = Currency.rub;
  static const _maxWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<NotificationsCubit>();
    final state = context.watch<NotificationsCubit>().state;
    final title = l10n.notificationsTitle;

    return AppGlassScaffold(
      leading: const AppBackButton(
        fallback: TabsRoute(children: [DashboardRoute()]),
      ),
      title: title,
      largeTitle: true,
      body: BaseLayout.slivers(
        largeTitle: title,
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          switch (state) {
            NotificationsLoading() => const SliverToBoxAdapter(
              child: SkeletonList(itemCount: 4, itemHeight: 72),
            ),
            NotificationsLoaded(:final notifications) => ContentSliverPadding(
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: Column(
                      spacing: 12,
                      children: [
                        for (final n in notifications)
                          NotificationCard(
                            notification: n,
                            currency: _currency,
                            onTap: n.isRead ? null : () => cubit.markRead(n.id),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            NotificationsEmpty() => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(l10n.notificationsEmpty)),
            ),
            NotificationsError(:final failure) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: FailureView(failure: failure, onRetry: cubit.load),
              ),
            ),
          },
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
