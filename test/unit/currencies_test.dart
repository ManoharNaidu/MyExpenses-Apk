import 'package:flutter_test/flutter_test.dart';
import 'package:my_expenses/core/constants/currencies.dart';

void main() {
  group('supportedCurrencies', () {
    test('list is not empty', () {
      expect(supportedCurrencies, isNotEmpty);
    });

    test('list is sorted by code', () {
      final codes = supportedCurrencies.map((c) => c.code).toList();
      final sorted = [...codes]..sort();
      expect(codes, equals(sorted));
    });

    test('AUD is present', () {
      expect(supportedCurrencies.any((c) => c.code == 'AUD'), isTrue);
    });

    test('USD is present', () {
      expect(supportedCurrencies.any((c) => c.code == 'USD'), isTrue);
    });

    test('all currencies have non-empty fields', () {
      for (final c in supportedCurrencies) {
        expect(c.code, isNotEmpty, reason: 'code empty for ${c.name}');
        expect(c.name, isNotEmpty, reason: 'name empty for ${c.code}');
        expect(c.symbol, isNotEmpty, reason: 'symbol empty for ${c.code}');
      }
    });

    test('label includes code and name', () {
      final aud =
          supportedCurrencies.firstWhere((c) => c.code == 'AUD');
      expect(aud.label, contains('AUD'));
      expect(aud.label, contains('Australian Dollar'));
    });
  });

  group('currencyFromCode()', () {
    test('finds known currency case-insensitively', () {
      final result = currencyFromCode('aud');
      expect(result.code, equals('AUD'));
      expect(result.name, equals('Australian Dollar'));
    });

    test('returns custom option for unknown code', () {
      final result = currencyFromCode('XYZ');
      expect(result.code, equals('XYZ'));
      expect(result.name, equals('Custom Currency'));
    });

    test('trims whitespace from input', () {
      final result = currencyFromCode('  USD  ');
      expect(result.code, equals('USD'));
    });
  });
}
