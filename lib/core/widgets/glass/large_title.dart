import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

/// Контроллер на каждый заголовок: у вкладок свои прокрутки, а один
/// ScrollController нельзя подключать к нескольким спискам.
class LargeTitleControllers {
  final _controllers = <String, GlassLargeTitleController>{};

  GlassLargeTitleController of(String title) =>
      _controllers.putIfAbsent(title, GlassLargeTitleController.new);

  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
  }
}

class LargeTitleScope extends InheritedWidget {
  const LargeTitleScope({super.key, required this.controllers, required super.child});

  final LargeTitleControllers controllers;

  static LargeTitleControllers? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LargeTitleScope>()?.controllers;

  @override
  bool updateShouldNotify(LargeTitleScope oldWidget) => controllers != oldWidget.controllers;
}

ScrollController? largeTitleScrollController(BuildContext context, String title) =>
    LargeTitleScope.maybeOf(context)?.of(title).scrollController;

class LargeTitleSliver extends StatelessWidget {
  const LargeTitleSliver({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final controllers = LargeTitleScope.maybeOf(context);
    if (controllers == null) return const SliverToBoxAdapter();

    return GlassLargeTitle(
      text: title,
      controller: controllers.of(title),
      padding: const EdgeInsetsDirectional.only(bottom: 8),
    );
  }
}
