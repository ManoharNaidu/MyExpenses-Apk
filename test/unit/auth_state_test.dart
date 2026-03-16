import 'package:flutter_test/flutter_test.dart';
import 'package:my_expenses/core/auth/auth_state.dart';

void main() {
  group('AuthState.initial()', () {
    test('starts with isLoading true and isLoggedIn false', () {
      final state = AuthState.initial();
      expect(state.isLoading, isTrue);
      expect(state.isLoggedIn, isFalse);
      expect(state.isOnboarded, isFalse);
      expect(state.isVerified, isFalse);
    });

    test('userId and email are null initially', () {
      final state = AuthState.initial();
      expect(state.userId, isNull);
      expect(state.userEmail, isNull);
    });

    test('appLock defaults to disabled', () {
      final state = AuthState.initial();
      expect(state.appLockEnabled, isFalse);
      expect(state.appLockUseBiometric, isFalse);
      expect(state.appLockPinHash, isNull);
    });
  });

  group('AuthState.copyWith()', () {
    test('copies only changed fields', () {
      final base = AuthState.initial();
      final updated = base.copyWith(
        isLoading: false,
        isLoggedIn: true,
        userName: 'Alice',
      );
      expect(updated.isLoading, isFalse);
      expect(updated.isLoggedIn, isTrue);
      expect(updated.userName, equals('Alice'));
      // unchanged fields preserved
      expect(updated.isOnboarded, isFalse);
      expect(updated.userId, isNull);
    });

    test('multiple copyWith calls chain correctly', () {
      final state = AuthState.initial()
          .copyWith(isLoading: false, isLoggedIn: true)
          .copyWith(isOnboarded: true, userEmail: 'a@b.com');
      expect(state.isLoggedIn, isTrue);
      expect(state.isOnboarded, isTrue);
      expect(state.userEmail, equals('a@b.com'));
    });
  });

  group('effectiveCurrency', () {
    test('returns AUD when currency is null', () {
      final state = AuthState.initial();
      expect(state.effectiveCurrency, equals('AUD'));
    });

    test('returns AUD when currency is empty string', () {
      final state = AuthState.initial().copyWith(userCurrency: '  ');
      expect(state.effectiveCurrency, equals('AUD'));
    });

    test('uppercases the stored currency code', () {
      final state = AuthState.initial().copyWith(userCurrency: 'usd');
      expect(state.effectiveCurrency, equals('USD'));
    });

    test('trims whitespace from currency code', () {
      final state = AuthState.initial().copyWith(userCurrency: ' inr ');
      expect(state.effectiveCurrency, equals('INR'));
    });
  });

  group('effectiveExpenseCategories', () {
    test('returns userExpenseCategories when set', () {
      final state = AuthState.initial().copyWith(
        userExpenseCategories: ['Food', 'Transport'],
      );
      expect(state.effectiveExpenseCategories, equals(['Food', 'Transport']));
    });

    test('falls back to userCategories when expenseCategories is null', () {
      final state = AuthState.initial().copyWith(
        userCategories: ['Misc', 'Food'],
        userExpenseCategories: null,
      );
      expect(state.effectiveExpenseCategories, equals(['Misc', 'Food']));
    });

    test('returns empty list when both are null', () {
      final state = AuthState.initial();
      expect(state.effectiveExpenseCategories, isEmpty);
    });
  });

  group('effectiveIncomeCategories', () {
    test('returns empty when null', () {
      expect(AuthState.initial().effectiveIncomeCategories, isEmpty);
    });

    test('returns the set list', () {
      final state = AuthState.initial()
          .copyWith(userIncomeCategories: ['Salary', 'Freelance']);
      expect(state.effectiveIncomeCategories, equals(['Salary', 'Freelance']));
    });
  });
}
