import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/user/presentation/cubit/profile_edit_cubit.dart';
import 'package:spendyholik/features/user/presentation/cubit/session_cubit.dart';
import 'package:spendyholik/features/user/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = getIt<SessionCubit>().state;
    return BlocProvider(
      create: (_) {
        final cubit = getIt<ProfileEditCubit>();
        if (session is SessionAuthenticated) cubit.init(session.user);
        return cubit;
      },
      child: const ProfileEditView(),
    );
  }
}

class ProfileEditView extends StatelessWidget {
  const ProfileEditView({super.key});

  static const _formMaxWidth = 560.0;
  static const _fallback = TabsRoute(children: [ProfileRoute()]);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ProfileEditCubit>();
    final title = l10n.profileEditTitle;

    return BlocConsumer<ProfileEditCubit, ProfileEditState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case FormStatus.success:
            showAppToast(context, l10n.profileSaved);
            navigateBack(context.router, _fallback);
          case FormStatus.failure:
            if (state.failure case final failure?) {
              showAppToast(context, failureMessage(l10n, failure), error: true);
            }
          case FormStatus.idle || FormStatus.submitting:
            break;
        }
      },
      builder: (context, state) => AppGlassScaffold(
        leading: const AppBackButton(fallback: _fallback),
        title: title,
        largeTitle: true,
        body: BaseLayout.slivers(
          largeTitle: title,
          slivers: [
            ContentSliverPadding(
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _formMaxWidth),
                    child: Padding(
                      padding: const .only(top: 12, bottom: 120),
                      child: ProfileForm(state: state, cubit: cubit),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
