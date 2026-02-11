import 'transaction_model.dart';

class StagedTransactionDraft {
  final String? stagingId;
  final DateTime date;
  final TxType type;
  final String category;
  final double amount;
  final String? description;
  final bool accepted;

  const StagedTransactionDraft({
    this.stagingId,
    required this.date,
    required this.type,
    required this.category,
    required this.amount,
    this.description,
    this.accepted = true,
  });

  StagedTransactionDraft copyWith({
    String? stagingId,
    DateTime? date,
    TxType? type,
    String? category,
    double? amount,
    String? description,
    bool? accepted,
  }) {
    return StagedTransactionDraft(
      stagingId: stagingId ?? this.stagingId,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      accepted: accepted ?? this.accepted,
    );
  }

  Map<String, dynamic> toConfirmJson() {
    return {
      if (stagingId != null) 'staging_id': stagingId,
      'date': date.toIso8601String().split('T').first,
      'type': type == TxType.income ? 'Income' : 'Expense',
      'category': category,
      'amount': amount,
      'description': description,
    };
  }

  static List<StagedTransactionDraft> fromUploadResponse(dynamic decoded) {
    dynamic source = decoded;

    if (decoded is Map<String, dynamic>) {
      source = decoded['transactions'] ?? decoded['data'] ?? decoded['results'] ?? [];
    }

    if (source is! List) return [];

    return source
        .whereType<Map>()
        .map((raw) => _fromMap(Map<String, dynamic>.from(raw)))
        .toList();
  }

  static StagedTransactionDraft _fromMap(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      final dateValue = json['date'] ?? json['transaction_date'] ?? DateTime.now().toIso8601String();
      parsedDate = DateTime.parse(dateValue.toString());
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final rawType = (json['type'] ?? json['expected_type'] ?? 'Expense').toString().toLowerCase();
    final type = rawType.contains('income') ? TxType.income : TxType.expense;

    final rawAmount = json['amount'] ?? json['value'] ?? 0;
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount.toString().replaceAll(',', '')) ?? 0;

    return StagedTransactionDraft(
      stagingId: json['staging_id']?.toString() ?? json['id']?.toString(),
      date: parsedDate,
      type: type,
      category: (json['category'] ?? json['expected_category'] ?? json['predicted_category'] ?? 'Misc').toString(),
      amount: amount,
      description: (json['description'] ?? json['narration'])?.toString(),
      accepted: (json['accepted'] as bool?) ?? true,
    );
  }
}