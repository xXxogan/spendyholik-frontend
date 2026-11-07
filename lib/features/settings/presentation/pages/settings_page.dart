import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/settings/presentation/cubit/data_reset_cubit.dart';
import 'package:spendyholik/features/settings/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _maxWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = l10n.settingsTitle;

    return BlocProvider(
      create: (_) => getIt<DataResetCubit>(),
      child: BlocListener<DataResetCubit, DataResetState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          switch (state.status) {
            case .success:
              showAppToast(context, l10n.settingsWiped);
            case .failure:
              if (state.failure case final failure?) {
                showAppToast(
                  context,
                  failureMessage(l10n, failure),
                  error: true,
                );
              }
            case .idle || .submitting:
          }
        },
        child: AppGlassScaffold(
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
                      child: const SettingsBody(),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }
}
