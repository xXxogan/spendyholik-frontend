import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/core/format/money_format.dart';
import 'package:spendyholik/core/models/currency.dart';

const nbsp = '\u00a0';
const minus = '\u2212';

void main() {
  test('ru: разряды через неразрывный пробел, знак валюты после суммы', () {
    expect(formatMoney(23005000, Currency.rub, 'ru'), '230${nbsp}050$nbsp₽');
  });

  test('копейки показываются, только если они есть', () {
    expect(formatMoney(124050, Currency.rub, 'ru'), '1${nbsp}240,50$nbsp₽');
    expect(formatMoney(124000, Currency.rub, 'ru'), '1${nbsp}240$nbsp₽');
  });

  test('отрицательная сумма — с типографским минусом', () {
    expect(
      formatMoney(-2340000, Currency.rub, 'ru'),
      '${minus}23${nbsp}400$nbsp₽',
    );
  });

  test('signed: плюс у положительной, ноль без знака', () {
    expect(
      formatMoney(11850000, Currency.rub, 'ru', signed: true),
      '+118${nbsp}500$nbsp₽',
    );
    expect(formatMoney(0, Currency.rub, 'ru', signed: true), '0$nbsp₽');
  });

  test('en: знак валюты перед суммой, разряды через запятую', () {
    expect(formatMoney(23005000, Currency.usd, 'en'), r'$230,050');
    expect(formatMoney(-124050, Currency.usd, 'en'), '$minus\$1,240.50');
  });

  test('compact ru: «120 тыс. ₽»', () {
    expect(
      formatMoneyCompact(12000000, Currency.rub, 'ru'),
      '120$nbspтыс.$nbsp₽',
    );
  });

  test('compact ru: малые суммы и миллионы', () {
    expect(formatMoneyCompact(50000, Currency.rub, 'ru'), '500$nbsp₽');
    expect(
      formatMoneyCompact(150000000, Currency.rub, 'ru'),
      '1,5$nbspмлн$nbsp₽',
    );
  });

  test('compact en', () {
    expect(formatMoneyCompact(12000000, Currency.usd, 'en'), r'$120K');
  });

  group('parseAmountInput', () {
    test(
      'пробелы и запятая',
      () => expect(parseAmountInput('1 240,5'), 124050),
    );
    test('nbsp', () => expect(parseAmountInput('1${nbsp}240,50'), 124050));
    test('точка', () => expect(parseAmountInput('1240.50'), 124050));
    test('целое', () => expect(parseAmountInput('300'), 30000));
    test('пусто, ноль, мусор', () {
      expect(parseAmountInput(''), isNull);
      expect(parseAmountInput('   '), isNull);
      expect(parseAmountInput('0'), isNull);
      expect(parseAmountInput('0,00'), isNull);
      expect(parseAmountInput('abc'), isNull);
      expect(parseAmountInput('12abc'), isNull);
      expect(parseAmountInput('1,2,3'), isNull);
    });
    test('отрицательное → null', () => expect(parseAmountInput('-5'), isNull));
    test('12 цифр в целой части — предел', () {
      expect(parseAmountInput('999999999999,99'), 99999999999999);
      expect(parseAmountInput('000001'), 100);
    });
    test('длиннее 12 цифр — null, без переполнения и исключений', () {
      expect(parseAmountInput('1000000000000'), isNull);
      expect(parseAmountInput('184467440737095517'), isNull);
      expect(parseAmountInput('12345678901234567890'), isNull);
    });
  });

  group('parseSignedAmountInput', () {
    test('ноль допустим', () => expect(parseSignedAmountInput('0'), 0));
    test('минус — дефис и типографский', () {
      expect(parseSignedAmountInput('-1 200,5'), -120050);
      expect(parseSignedAmountInput('\u22121200'), -120000);
    });
    test('положительное', () => expect(parseSignedAmountInput('5000'), 500000));
    test('пусто и мусор → null', () {
      expect(parseSignedAmountInput(''), isNull);
      expect(parseSignedAmountInput('-'), isNull);
      expect(parseSignedAmountInput('1-2'), isNull);
    });
  });

  group('formatAmountInput', () {
    test('целое — без дробной части', () {
      expect(formatAmountInput(8425000), '84250');
    });
    test(
      'копейки через точку',
      () => expect(formatAmountInput(124050), '1240.50'),
    );
    test('отрицательное', () => expect(formatAmountInput(-120000), '-1200'));
    test(
      'туда и обратно',
      () => expect(parseSignedAmountInput(formatAmountInput(-124005)), -124005),
    );
  });
}
