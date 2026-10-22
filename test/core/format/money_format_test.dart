import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/core/format/money_format.dart';
import 'package:spendyholik/core/models/currency.dart';

const nbsp = ' ';
const minus = '−';

void main() {
  test('ru: разряды через неразрывный пробел, знак валюты после суммы', () {
    expect(formatMoney(23005000, Currency.rub, 'ru'), '230${nbsp}050$nbsp₽');
  });

  test('копейки показываются, только если они есть', () {
    expect(formatMoney(124050, Currency.rub, 'ru'), '1${nbsp}240,50$nbsp₽');
    expect(formatMoney(124000, Currency.rub, 'ru'), '1${nbsp}240$nbsp₽');
  });

  test('отрицательная сумма — с типографским минусом', () {
    expect(formatMoney(-2340000, Currency.rub, 'ru'), '${minus}23${nbsp}400$nbsp₽');
  });

  test('signed: плюс у положительной, ноль без знака', () {
    expect(formatMoney(11850000, Currency.rub, 'ru', signed: true), '+118${nbsp}500$nbsp₽');
    expect(formatMoney(0, Currency.rub, 'ru', signed: true), '0$nbsp₽');
  });

  test('en: знак валюты перед суммой, разряды через запятую', () {
    expect(formatMoney(23005000, Currency.usd, 'en'), r'$230,050');
    expect(formatMoney(-124050, Currency.usd, 'en'), '$minus\$1,240.50');
  });
}
