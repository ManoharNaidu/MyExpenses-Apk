import 'package:flutter_test/flutter_test.dart';
import 'package:my_expenses/models/outbox_operation.dart';

void main() {
  group('OutboxOperation.generateId()', () {
    test('generates a non-empty string', () {
      expect(OutboxOperation.generateId(), isNotEmpty);
    });

    test('generates unique IDs', () {
      final ids = List.generate(50, (_) => OutboxOperation.generateId()).toSet();
      expect(ids.length, equals(50));
    });

    test('id starts with op_', () {
      expect(OutboxOperation.generateId(), startsWith('op_'));
    });
  });

  group('OutboxOperation.toJson / fromJson', () {
    test('roundtrips createTransaction op', () {
      final op = OutboxOperation(
        id: 'op-1',
        type: OutboxOperationType.createTransaction,
        entityId: 'tx-local-1',
        payload: {'amount': 50.0, 'type': 'expense'},
        createdAt: DateTime(2026, 3, 15),
        retryCount: 0,
      );
      final json = op.toJson();
      final restored = OutboxOperation.fromJson(json);

      expect(restored.id, equals('op-1'));
      expect(restored.type, equals(OutboxOperationType.createTransaction));
      expect(restored.entityId, equals('tx-local-1'));
      expect(restored.retryCount, equals(0));
    });

    test('roundtrips deleteTransaction op', () {
      final op = OutboxOperation(
        id: 'op-2',
        type: OutboxOperationType.deleteTransaction,
        entityId: 'tx-server-99',
        payload: null,
        createdAt: DateTime(2026, 1, 1),
      );
      final restored = OutboxOperation.fromJson(op.toJson());
      expect(restored.type, equals(OutboxOperationType.deleteTransaction));
      expect(restored.entityId, equals('tx-server-99'));
    });

    test('roundtrips confirmStaging op with list payload', () {
      final confirmations = [
        {'id': 's-1', 'final_type': 'expense', 'final_category': 'Food'}
      ];
      final op = OutboxOperation(
        id: 'op-3',
        type: OutboxOperationType.confirmStaging,
        payload: confirmations,
        createdAt: DateTime(2026, 1, 1),
      );
      final restored = OutboxOperation.fromJson(op.toJson());
      expect(restored.type, equals(OutboxOperationType.confirmStaging));
    });

    test('handles missing created_at gracefully', () {
      final json = {
        'id': 'op-x',
        'type': 'updateTransaction',
        'payload': {},
        // no created_at
      };
      final op = OutboxOperation.fromJson(json);
      expect(op.type, equals(OutboxOperationType.updateTransaction));
    });

    test('parses legacy snake_case type names', () {
      final types = {
        'create_transaction': OutboxOperationType.createTransaction,
        'update_transaction': OutboxOperationType.updateTransaction,
        'delete_transaction': OutboxOperationType.deleteTransaction,
        'confirm_staging': OutboxOperationType.confirmStaging,
      };
      for (final entry in types.entries) {
        final op = OutboxOperation.fromJson({
          'id': 'x',
          'type': entry.key,
          'payload': {},
          'created_at': '2026-01-01T00:00:00.000',
        });
        expect(op.type, equals(entry.value), reason: 'Failed for ${entry.key}');
      }
    });
  });

  group('OutboxOperation.copyWith()', () {
    test('increments retryCount', () {
      final op = OutboxOperation(
        id: 'op-1',
        type: OutboxOperationType.createTransaction,
        payload: {},
        createdAt: DateTime(2026, 1, 1),
        retryCount: 2,
      );
      final retried = op.copyWith(retryCount: 3, lastError: 'timeout');
      expect(retried.retryCount, equals(3));
      expect(retried.lastError, equals('timeout'));
      expect(retried.id, equals('op-1'));
    });

    test('clearEntityId sets entityId to null', () {
      final op = OutboxOperation(
        id: 'op-1',
        type: OutboxOperationType.updateTransaction,
        entityId: 'tx-old',
        payload: {},
        createdAt: DateTime(2026, 1, 1),
      );
      final cleared = op.copyWith(clearEntityId: true);
      expect(cleared.entityId, isNull);
    });
  });
}
