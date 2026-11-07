import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/app/router/guards.dart';
import 'package:spendyholik/app/theme/app_colors.dart';
import 'package:spendyholik/features/user/presentation/cubit/onboarding_cubit.dart';
import 'package:spendyholik/features/user/presentation/cubit/session_cubit.dart';
import 'package:spendyholik/features/user/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OnboardingCubit>(),
      child: const OnboardingView(),
    );
  }
}

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  static const _maxWidth = 440.0;

  final _pages = PageController();

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Онбординг виден и вошедшему (фаза 1, прямая ссылка) — тогда дальше по сессии.
  void _finish() {
    if (!mounted) return;
    final session = getIt<SessionCubit>().state;
    context.router.replaceAll([
      if (session is SessionAuthenticated)
        splashRoute(session)!
      else
        const LoginRoute(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final cubit = context.read<OnboardingCubit>();
    final slides = [
      OnboardingSlide(
        icon: Icons.account_balance_wallet_outlined,
        color: theme.colorScheme.primary,
        title: l10n.onboardingAccountsTitle,
        text: l10n.onboardingAccountsText,
      ),
      OnboardingSlide(
        icon: Icons.insights_outlined,
        color: AppColors.positive(brightness),
        title: l10n.onboardingAnalyticsTitle,
        text: l10n.onboardingAnalyticsText,
      ),
      OnboardingSlide(
        icon: Icons.flag_outlined,
        color: AppColors.warning(brightness),
        title: l10n.onboardingGoalsTitle,
        text: l10n.onboardingGoalsText,
      ),
    ];

    return BlocConsumer<OnboardingCubit, int>(
      listener: (_, page) => _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ),
      builder: (context, page) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: Padding(
                padding: const .all(24),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pages,
                        onPageChanged: cubit.goTo,
                        children: slides,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: .center,
                      spacing: 8,
                      children: [
                        for (var i = 0; i < slides.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: i == page ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == page
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              borderRadius: .circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () async {
                        if (await cubit.next()) _finish();
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: Text(
                        page == OnboardingCubit.lastPage
                            ? l10n.onboardingStart
                            : l10n.onboardingNext,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        await cubit.skip();
                        _finish();
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(l10n.onboardingSkip),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
