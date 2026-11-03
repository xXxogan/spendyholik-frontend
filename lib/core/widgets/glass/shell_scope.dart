import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/side_nav_metrics.dart';

/// Отступ слева под плавающую боковую панель оболочки: страница рисует фон
/// на всю ширину, а шапку и контент сдвигает на [leftInset].
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.leftInset, required super.child});

  final double leftInset;

  static double leftInsetOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>()?.leftInset ?? 0;

  /// Сдвиг шапки вниз. Под оболочкой: кнопки 40 стоят в строке 44 на 2 ниже
  /// её верха — так их верх вровень с верхом боковой панели. На телефоне:
  /// бейдж счётчика выступает над кнопкой на 8 и без сдвига уходил за край
  /// экрана (Web и Android без выреза).
  static double appBarTopOf(BuildContext context) =>
      leftInsetOf(context) == 0 ? _compactBarTop : SideNavMetrics.gap - 2;

  static const _compactBarTop = 6.0;

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      leftInset != oldWidget.leftInset;
}
