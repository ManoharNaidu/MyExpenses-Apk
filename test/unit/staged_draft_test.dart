import 'package:flutter_test/flutter_test.dart';
import 'package:my_expenses/models/staged_transaction_draft.dart';
import 'package:my_expenses/models/transaction_model.dart';

void main() {
  final baseDate = DateTime(2026, 3, 15);

  StagedTransactionDraft makeDraft({
    String? stagingId = 'staging-1',
    TxType predictedType = TxType.expense,
    String predictedCategory = 'Food',
    TxType? stagedType,
    String? stagedCategory,
    double amount = 25.0,
  }) {
    return StagedTransactionDraft(
      stagingId: stagingId,
      date: baseDate,
      predictedType: predictedType,
      predictedCategory: predictedCategory,
      stagedType: stagedType,
      stagedCategory: stagedCategory,
      amount: amount,
    );
  }

  group('StagedTransactionDraft.toConfirmJson()', () {
    test('returns correct structure for expense', () {
      final draft = makeDraft(
        stagedType: TxType.expense,
        stagedCategory: 'Groceries',
      );
      final json = draft.toConfirmJson();
      expect(json['id'], equals('staging-1'));
      expect(json['final_type'], equals('expense'));
      expect(json['final_category'], equals('Groceries'));
    });

    test('returns income for income type', () {
      final draft = makeDraft(
        stagedType: TxType.income,
        stagedCategory: 'Salary',
      );
      expect(draft.toConfirmJson()['final_type'], equals('income'));
    });
  });

  group('StagedTransactionDraft.copyWith()', () {
    test('updates stagedType without touching other fields', () {
      final draft = makeDraft();
      final updated = draft.copyWith(stagedType: TxType.income);
      expect(updated.stagedType, equals(TxType.income));
      expect(updated.amount, equals(draft.amount));
      expect(updated.predictedCategory, equals(draft.predictedCategory));
    });

    test('clearStagedType sets stagedType to null', () {
      final draft = makeDraft(stagedType: TxType.expense);
      final cleared = draft.copyWith(clearStagedType: true);
      expect(cleared.stagedType, isNull);
    });

    test('clearStagedCategory sets stagedCategory to null', () {
      final draft = makeDraft(stagedCategory: 'Food');
      final cleared = draft.copyWith(clearStagedCategory: true);
      expect(cleared.stagedCategory, isNull);
    });

    test('accepted flag toggled correctly', () {
      final draft = makeDraft();
      expect(draft.accepted, isTrue);
      final deselected = draft.copyWith(accepted: false);
      expect(deselected.accepted, isFalse);
    });
  });

  group('StagedTransactionDraft.fromUploadResponse()', () {
    test('parses a list of raw maps', () {
      final raw = [
        {
          'id': 's-1',
          'date': '2026-03-15',
          'type': 'expense',
          'category': 'Food',
          'predicted_category': 'Food',
          'amount': 30.0,
        },
        {
          'id': 's-2',
          'date': '2026-03-16',
          'type': 'income',
          'category': 'Job',
          'predicted_category': 'Job',
          'amount': 2000.0,
        },
      ];
      final drafts = StagedTransactionDraft.fromUploadResponse(raw);
      expect(drafts.length, equals(2));
      expect(drafts[0].predictedType, equals(TxType.expense));
      expect(drafts[1].predictedType, equals(TxType.income));
      expect(drafts[1].amount, equals(2000.0));
    });

    test('returns empty list for empty input', () {
      expect(StagedTransactionDraft.fromUploadResponse([]), isEmpty);
    });

    test('returns empty list for null-like input', () {
      expect(StagedTransactionDraft.fromUploadResponse('not a list'), isEmpty);
    });

    test('wraps response object with transactions key', () {
      final wrapped = {
        'transactions': [
          {
            'id': 's-1',
            'date': '2026-01-01',
            'type': 'expense',
            'category': 'Misc',
            'amount': 10.0,
          }
        ]
      };
      final drafts = StagedTransactionDraft.fromUploadResponse(wrapped);
      expect(drafts.length, equals(1));
    });

    test('handles missing date gracefully', () {
      final raw = [
        {'id': 's-1', 'type': 'expense', 'category': 'Food', 'amount': 5.0},
      ];
      final drafts = StagedTransactionDraft.fromUploadResponse(raw);
      expect(drafts.length, equals(1));
      // Date should default to now, not throw
    });

    test('handles credit type as income', () {
      final raw = [
        {
          'id': 's-1',
          'date': '2026-01-01',
          'type': 'credit',
          'category': 'Transfer',
          'amount': 500.0,
        }
      ];
      final drafts = StagedTransactionDraft.fromUploadResponse(raw);
      expect(drafts.first.predictedType, equals(TxType.income));
    });
  });

  group('StagedTransactionDraft.toJson / fromJson roundtrip', () {
    test('roundtrips correctly', () {
      final original = makeDraft(
        stagingId: 'rt-1',
        stagedType: TxType.expense,
        stagedCategory: 'Transport',
        amount: 12.50,
      );
      final json = original.toJson();
      final restored = StagedTransactionDraft.fromJson(json);
      expect(restored.stagingId, equals(original.stagingId));
      expect(restored.amount, equals(original.amount));
      expect(restored.stagedType, equals(original.stagedType));
      expect(restored.stagedCategory, equals(original.stagedCategory));
    });
  });
}
