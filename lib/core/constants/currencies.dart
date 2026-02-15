class CurrencyOption {
  final String code;
  final String name;
  final String symbol;

  const CurrencyOption({
    required this.code,
    required this.name,
    required this.symbol,
  });

  String get label => '$symbol  $code • $name';
}

const List<CurrencyOption> supportedCurrencies = [
  CurrencyOption(code: 'AUD', name: 'Australian Dollar', symbol: r'$'),
  CurrencyOption(code: 'USD', name: 'US Dollar', symbol: r'$'),
  CurrencyOption(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
  CurrencyOption(code: 'EUR', name: 'Euro', symbol: '€'),
  CurrencyOption(code: 'GBP', name: 'British Pound', symbol: '£'),
  CurrencyOption(code: 'CAD', name: 'Canadian Dollar', symbol: r'$'),
  CurrencyOption(code: 'NZD', name: 'New Zealand Dollar', symbol: r'$'),
  CurrencyOption(code: 'SGD', name: 'Singapore Dollar', symbol: r'$'),
  CurrencyOption(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
  CurrencyOption(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
  CurrencyOption(code: 'HKD', name: 'Hong Kong Dollar', symbol: r'$'),
  CurrencyOption(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ'),
  CurrencyOption(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼'),
  CurrencyOption(code: 'QAR', name: 'Qatari Riyal', symbol: '﷼'),
  CurrencyOption(code: 'ZAR', name: 'South African Rand', symbol: 'R'),
  CurrencyOption(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF'),
  CurrencyOption(code: 'SEK', name: 'Swedish Krona', symbol: 'kr'),
  CurrencyOption(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr'),
  CurrencyOption(code: 'DKK', name: 'Danish Krone', symbol: 'kr'),
  CurrencyOption(code: 'BRL', name: 'Brazilian Real', symbol: r'R$'),
];

CurrencyOption currencyFromCode(String code) {
  final normalized = code.trim().toUpperCase();
  return supportedCurrencies.firstWhere(
    (c) => c.code == normalized,
    orElse: () => CurrencyOption(
      code: normalized,
      name: 'Custom Currency',
      symbol: normalized,
    ),
  );
}
