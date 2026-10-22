import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/widgets.dart';

/// Возврат назад, а если возвращаться некуда — на логического родителя.
/// Стек пуст, когда страницу открыли по URL или обновили на Web.
Future<void> navigateBack(StackRouter router, PageRouteInfo fallback) async {
  if (router.canPop()) {
    await router.maybePop();
  } else {
    await router.replaceAll([fallback]);
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.fallback});

  final PageRouteInfo fallback;

  @override
  Widget build(BuildContext context) {
    return AppGlassIconButton(
      icon: Icons.adaptive.arrow_back,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => navigateBack(context.router, fallback),
    );
  }
}
