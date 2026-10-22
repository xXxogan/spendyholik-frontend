import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/large_title_controllers.dart';

class LargeTitleScope extends InheritedWidget {
  const LargeTitleScope({
    super.key,
    required this.controllers,
    required super.child,
  });

  final LargeTitleControllers controllers;

  static LargeTitleControllers? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LargeTitleScope>()?.controllers;

  @override
  bool updateShouldNotify(LargeTitleScope oldWidget) =>
      controllers != oldWidget.controllers;
}

ScrollController? largeTitleScrollController(
  BuildContext context,
  String title,
) => LargeTitleScope.maybeOf(context)?.of(title).scrollController;
