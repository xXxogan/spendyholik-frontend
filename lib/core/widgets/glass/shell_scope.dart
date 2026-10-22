import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/widgets/glass/side_nav_metrics.dart';

/// Отступ слева под плавающую боковую панель оболочки: страница рисует фон
/// на всю ширину, а шапку и контент сдвигает на [leftInset].
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.leftInset, required super.child});

  final double leftInset;

  static double leftInsetOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>()?.leftInset ?? 0;

  /// Сдвиг шапки вниз под оболочкой: кнопки 40 стоят в строке 44 на 2 ниже
  /// её верха — так их верх вровень с верхом боковой панели.
  static double appBarTopOf(BuildContext context) =>
      leftInsetOf(context) == 0 ? 0 : SideNavMetrics.gap - 2;

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      leftInset != oldWidget.leftInset;
}
