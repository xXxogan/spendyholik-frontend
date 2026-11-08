import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/models/currency.dart';

/// Базовая валюта текущей сессии для data-слоя: репозиториям нельзя читать
/// SessionCubit (слой выше). Пишет её AuthRepository при каждой смене пользователя.
@lazySingleton
class SessionCurrency {
  Currency value = Currency.rub;
}
