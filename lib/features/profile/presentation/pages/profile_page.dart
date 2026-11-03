import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/profile/presentation/widgets/widgets.dart';
import 'package:spendyholik/features/user/user.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _maxWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final negative = AppColors.negative(Theme.of(context).brightness);

    return BaseLayout.slivers(
      largeTitle: l10n.navProfile,
      slivers: [
        ContentSliverPadding(
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: Padding(
                  padding: const .only(top: 12, bottom: 120),
                  child: Column(
                    crossAxisAlignment: .stretch,
                    spacing: 16,
                    children: [
                      const ProfileHeader(),
                      const ProfileMenu(),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => getIt<SessionCubit>().signOut(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: negative,
                          side: BorderSide(color: negative),
                        ),
                        child: Text(l10n.profileSignOut),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
