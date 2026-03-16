import 'package:flutter_test/flutter_test.dart';
import 'package:my_expenses/core/security/pin_utils.dart';

void main() {
  group('hashPin()', () {
    test('returns a 64-char hex SHA-256 digest', () {
      final hash = hashPin('1234');
      expect(hash.length, equals(64));
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(hash), isTrue);
    });

    test('same PIN produces same hash', () {
      expect(hashPin('5678'), equals(hashPin('5678')));
    });

    test('different PINs produce different hashes', () {
      expect(hashPin('1111'), isNot(equals(hashPin('2222'))));
    });

    test('trims whitespace before hashing', () {
      expect(hashPin(' 1234 '), equals(hashPin('1234')));
    });

    test('empty string hashes without error', () {
      final hash = hashPin('');
      expect(hash.length, equals(64));
    });
  });
}
