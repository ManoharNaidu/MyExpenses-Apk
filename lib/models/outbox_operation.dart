import 'dart:math';

enum OutboxOperationType {
  createTransaction,
  updateTransaction,
  deleteTransaction,
  confirmStaging,
}

class OutboxOperation {
  final String id;
  final OutboxOperationType type;
  final String? entityId;
  final dynamic payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  const OutboxOperation({
    required this.id,
    required this.type,
    this.entityId,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  static final Random _random = Random();

  static String generateId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    // Use 31-bit max to stay safe across all Dart targets (including web/JS).
    final rand = _random.nextInt(0x7fffffff).toRadixString(16);
    return 'op_${now}_$rand';
  }

  OutboxOperation copyWith({
    String? id,
    OutboxOperationType? type,
    String? entityId,
    bool clearEntityId = false,
    dynamic payload,
    DateTime? createdAt,
    int? retryCount,
    String? lastError,
    bool clearLastError = false,
  }) {
    return OutboxOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      entityId: clearEntityId ? null : (entityId ?? this.entityId),
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'entity_id': entityId,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }

  factory OutboxOperation.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString() ?? '';

    OutboxOperationType parseType(String value) {
      switch (value) {
        case 'createTransaction':
        case 'create_transaction':
        case 'create':
          return OutboxOperationType.createTransaction;
        case 'updateTransaction':
        case 'update_transaction':
        case 'update':
          return OutboxOperationType.updateTransaction;
        case 'deleteTransaction':
        case 'delete_transaction':
        case 'delete':
          return OutboxOperationType.deleteTransaction;
        case 'confirmStaging':
        case 'confirm_staging':
        case 'confirmStagingTransaction':
          return OutboxOperationType.confirmStaging;
        default:
          return OutboxOperationType.updateTransaction;
      }
    }

    final type = parseType(rawType);

    return OutboxOperation(
      id: json['id']?.toString() ?? generateId(),
      type: type,
      entityId: json['entity_id']?.toString(),
      payload: json['payload'],
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      lastError: json['last_error']?.toString(),
    );
  }
}
