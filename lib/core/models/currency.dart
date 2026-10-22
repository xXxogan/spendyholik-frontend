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
}
