import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/models/money_dto.dart';

void main() {
  test('MoneyDto из ответа API — minor и валюта', () {
    final money = MoneyDto.fromJson(const {
      'minor': 1050000,
      'currency': 'USD',
      'formatted': r'$10,500.00',
    });
    expect(money.minor, 1050000);
    expect(money.currency, 'USD');
  });

  test(
    'Currency.fromCode: известный код в любом регистре, неизвестный — null',
    () {
      expect(Currency.fromCode('usd'), Currency.usd);
      expect(Currency.fromCode('XYZ'), isNull);
      expect(Currency.fromCode(null), isNull);
    },
  );
}
