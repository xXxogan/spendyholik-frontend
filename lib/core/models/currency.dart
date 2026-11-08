enum Currency {
  rub('RUB', '₽'),
  usd('USD', r'$'),
  eur('EUR', '€'),
  kzt('KZT', '₸'),
  byn('BYN', 'Br'),
  gel('GEL', '₾'),
  uah('UAH', '₴'),
  cny('CNY', '¥');

  const Currency(this.code, this.symbol);

  final String code;
  final String symbol;

  /// null — валюты нет в приложении (API принимает любой код ISO 4217).
  static Currency? fromCode(String? code) => code == null
      ? null
      : values.where((c) => c.code == code.toUpperCase()).firstOrNull;
}
