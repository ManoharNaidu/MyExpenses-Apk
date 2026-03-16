import 'package:flutter_test/flutter_test.dart';
import 'package:my_expenses/models/transaction_model.dart';

void main() {
  group('TransactionModel.fromJson()', () {
    test('parses income transaction', () {
      final json = {
        'id': 'tx-1',
        'user_id': 'u-1',
        'date': '2026-03-15',
        'description': 'Salary',
        'type': 'income',
        'category': 'Job',
        'amount': 2500.0,
      };
      final tx = TransactionModel.fromJson(json);
      expect(tx.id, equals('tx-1'));
      expect(tx.type, equals(TxType.income));
      expect(tx.amount, equals(2500.0));
      expect(tx.category, equals('Job'));
    });

    test('parses expense transaction', () {
      final json = {
        'id': 'tx-2',
        'date': '2026-03-01',
        'type': 'expense',
        'category': 'Food',
        'amount': 45.50,
      };
      final tx = TransactionModel.fromJson(json);
      expect(tx.type, equals(TxType.expense));
      expect(tx.amount, equals(45.50));
    });

    test('maps credit type to income', () {
      final tx = TransactionModel.fromJson({
        'date': '2026-01-01',
        'type': 'credit',
        'category': 'Transfer',
        'amount': 100.0,
      });
      expect(tx.type, equals(TxType.income));
    });

    test('maps debit type to expense', () {
      final tx = TransactionModel.fromJson({
        'date': '2026-01-01',
        'type': 'debit',
        'category': 'Groceries',
        'amount': 30.0,
      });
      expect(tx.type, equals(TxType.expense));
    });

    test('unknown type defaults to expense', () {
      final tx = TransactionModel.fromJson({
        'date': '2026-01-01',
        'type': 'random',
        'category': 'Misc',
        'amount': 10.0,
      });
      expect(tx.type, equals(TxType.expense));
    });

    test('uses notes field for description when both present', () {
      final tx = TransactionModel.fromJson({
        'date': '2026-01-01',
        'type': 'expense',
        'category': 'Food',
        'amount': 5.0,
        'description': 'old desc',
        'notes': 'Coffee',
      });
      expect(tx.notes, equals('Coffee'));
    });

    test('parses repeatMonthly flag', () {
      final tx = TransactionModel.fromJson({
        'date': '2026-01-01',
        'type': 'expense',
        'category': 'Rent',
        'amount': 1200.0,
        'repeat_monthly': true,
      });
      expect(tx.repeatMonthly, isTrue);
    });

    test('repeatMonthly defaults to false', () {
      final tx = TransactionModel.fromJson({
        'date': '2026-01-01',
        'type': 'expense',
        'category': 'Food',
        'amount': 20.0,
      });
      expect(tx.repeatMonthly, isFalse);
    });
  });

  group('TransactionModel.toJson()', () {
    test('formats date as YYYY-MM-DD only', () {
      final tx = TransactionModel(
        date: DateTime(2026, 3, 15),
        type: TxType.expense,
        category: 'Food',
        amount: 25.0,
      );
      final json = tx.toJson();
      expect(json['date'], equals('2026-03-15'));
    });

    test('omits id when null', () {
      final tx = TransactionModel(
        date: DateTime(2026, 1, 1),
        type: TxType.expense,
        category: 'Food',
        amount: 10.0,
      );
      final json = tx.toJson();
      expect(json.containsKey('id'), isFalse);
    });

    test('includes id when set', () {
      final tx = TransactionModel(
        id: 'tx-123',
        date: DateTime(2026, 1, 1),
        type: TxType.income,
        category: 'Job',
        amount: 3000.0,
      );
      final json = tx.toJson();
      expect(json['id'], equals('tx-123'));
    });

    test('serialises income type as string "income"', () {
      final tx = TransactionModel(
        date: DateTime(2026, 1, 1),
        type: TxType.income,
        category: 'Salary',
        amount: 1000.0,
      );
      expect(tx.toJson()['type'], equals('income'));
    });

    test('serialises expense type as string "expense"', () {
      final tx = TransactionModel(
        date: DateTime(2026, 1, 1),
        type: TxType.expense,
        category: 'Food',
        amount: 50.0,
      );
      expect(tx.toJson()['type'], equals('expense'));
    });

    test('omits recurringId when null', () {
      final tx = TransactionModel(
        date: DateTime(2026, 1, 1),
        type: TxType.expense,
        category: 'Food',
        amount: 10.0,
      );
      expect(tx.toJson().containsKey('recurring_id'), isFalse);
    });

    test('includes repeat_monthly only when true', () {
      final tx = TransactionModel(
        date: DateTime(2026, 1, 1),
        type: TxType.expense,
        category: 'Rent',
        amount: 1200.0,
        repeatMonthly: true,
      );
      expect(tx.toJson()['repeat_monthly'], isTrue);
    });

    test('does not send user_id to backend', () {
      final tx = TransactionModel(
        userId: 'u-secret',
        date: DateTime(2026, 1, 1),
        type: TxType.expense,
        category: 'Food',
        amount: 10.0,
      );
      expect(tx.toJson().containsKey('user_id'), isFalse);
    });
  });
}
