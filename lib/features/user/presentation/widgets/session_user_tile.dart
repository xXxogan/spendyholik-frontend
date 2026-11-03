import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/features/user/presentation/cubit/session_cubit.dart';
import 'package:spendyholik/features/user/presentation/widgets/user_avatar.dart';

/// Текущий пользователь внизу боковой панели; узкая панель — только аватар.
class SessionUserTile extends StatelessWidget {
  const SessionUserTile({
    super.key,
    required this.extended,
    required this.onTap,
  });

  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SessionCubit, SessionState>(
      bloc: getIt<SessionCubit>(),
      builder: (context, state) {
        if (state is! SessionAuthenticated) return const SizedBox.shrink();
        final user = state.user;
        return Tooltip(
          message: extended ? '' : user.name,
          child: InkWell(
            onTap: onTap,
            borderRadius: .circular(16),
            child: Padding(
              padding: const .all(8),
              child: Row(
                mainAxisSize: extended ? .max : .min,
                spacing: 12,
                children: [
                  // Рейл внутри 48: аватар 32 и отступы 2×8.
                  UserAvatar(name: user.name, size: extended ? 36 : 32),
                  if (extended)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            user.name,
                            style: theme.textTheme.titleSmall,
                            overflow: .ellipsis,
                          ),
                          Text(
                            user.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: .ellipsis,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
