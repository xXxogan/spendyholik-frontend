import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

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
