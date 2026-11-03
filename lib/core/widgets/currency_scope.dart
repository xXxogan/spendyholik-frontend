import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/models/currency.dart';

/// Базовая валюта пользователя для всех сумм; ставится в корне приложения
/// из сессии.
class CurrencyScope extends InheritedWidget {
  const CurrencyScope({
    super.key,
    required this.currency,
    required super.child,
  });

  final Currency currency;

  /// Без scope (виджет-тесты отдельных экранов) — рубль, валюта сида.
  static Currency of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CurrencyScope>()?.currency ??
      Currency.rub;

  @override
  bool updateShouldNotify(CurrencyScope oldWidget) =>
      currency != oldWidget.currency;
}
