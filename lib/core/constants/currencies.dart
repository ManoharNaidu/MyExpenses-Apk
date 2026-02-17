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

final List<CurrencyOption> supportedCurrencies = [
  const CurrencyOption(code: 'AUD', name: 'Australian Dollar', symbol: r'$'),
  const CurrencyOption(code: 'USD', name: 'US Dollar', symbol: r'$'),
  const CurrencyOption(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
  const CurrencyOption(code: 'EUR', name: 'Euro', symbol: '€'),
  const CurrencyOption(code: 'GBP', name: 'British Pound', symbol: '£'),
  const CurrencyOption(code: 'CAD', name: 'Canadian Dollar', symbol: r'$'),
  const CurrencyOption(code: 'NZD', name: 'New Zealand Dollar', symbol: r'$'),
  const CurrencyOption(code: 'SGD', name: 'Singapore Dollar', symbol: r'$'),
  const CurrencyOption(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
  const CurrencyOption(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
  const CurrencyOption(code: 'HKD', name: 'Hong Kong Dollar', symbol: r'$'),
  const CurrencyOption(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ'),
  const CurrencyOption(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼'),
  const CurrencyOption(code: 'QAR', name: 'Qatari Riyal', symbol: '﷼'),
  const CurrencyOption(code: 'ZAR', name: 'South African Rand', symbol: 'R'),
  const CurrencyOption(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF'),
  const CurrencyOption(code: 'SEK', name: 'Swedish Krona', symbol: 'kr'),
  const CurrencyOption(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr'),
  const CurrencyOption(code: 'DKK', name: 'Danish Krone', symbol: 'kr'),
  const CurrencyOption(code: 'BRL', name: 'Brazilian Real', symbol: r'R$'),
]..sort((a, b) => a.code.compareTo(b.code));

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
