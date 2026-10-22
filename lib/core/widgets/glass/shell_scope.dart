import 'package:material_ui/material_ui.dart';

/// Отступ слева под плавающую боковую панель оболочки: страница рисует фон
/// на всю ширину, а шапку и контент сдвигает на [leftInset].
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.leftInset, required super.child});

  final double leftInset;

  static double leftInsetOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>()?.leftInset ?? 0;

  @override
  bool updateShouldNotify(ShellScope oldWidget) => leftInset != oldWidget.leftInset;
}
