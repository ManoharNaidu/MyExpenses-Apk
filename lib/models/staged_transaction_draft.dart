// ignore_for_file: non_constant_identifier_names

import 'transaction_model.dart';

class StagedTransactionDraft {
  final String? stagingId;
  final DateTime date;
  final TxType predictedType;
  final String predictedCategory;
  final TxType? stagedType;
  final String? stagedCategory;
  final double amount;
  final String? description;
  final bool accepted;

  const StagedTransactionDraft({
    this.stagingId,
    required this.date,
    required this.predictedType,
    required this.predictedCategory,
    this.stagedType,
    this.stagedCategory,
    required this.amount,
    this.description,
    this.accepted = true,
  });

  StagedTransactionDraft copyWith({
    String? stagingId,
    DateTime? date,
    TxType? predictedType,
    String? predictedCategory,
    TxType? stagedType,
    String? stagedCategory,
    bool clearStagedType = false,
    bool clearStagedCategory = false,
    double? amount,
    String? description,
    bool? accepted,
  }) {
    return StagedTransactionDraft(
      stagingId: stagingId ?? this.stagingId,
      date: date ?? this.date,
      predictedType: predictedType ?? this.predictedType,
      predictedCategory: predictedCategory ?? this.predictedCategory,
      stagedType: clearStagedType ? null : (stagedType ?? this.stagedType),
      stagedCategory: clearStagedCategory
          ? null
          : (stagedCategory ?? this.stagedCategory),
      amount: amount ?? this.amount,
      description: description ?? this.description,
      accepted: accepted ?? this.accepted,
    );
  }

  Map<String, dynamic> toConfirmJson() {
    return {
      'id': stagingId,
      'final_type': stagedType == TxType.income ? 'income' : 'expense',
      'final_category': stagedCategory,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'staging_id': stagingId,
      'date': date.toIso8601String(),
      'predicted_type': predictedType == TxType.income ? 'income' : 'expense',
      'predicted_category': predictedCategory,
      'staged_type': stagedType == null
          ? null
          : (stagedType == TxType.income ? 'income' : 'expense'),
      'staged_category': stagedCategory,
      'amount': amount,
      'description': description,
      'accepted': accepted,
    };
  }

  factory StagedTransactionDraft.fromJson(Map<String, dynamic> json) {
    final parsedDate =
        DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now();

    TxType parseType(dynamic value) {
      final raw = (value ?? '').toString().toLowerCase();
      return raw.contains('income') ? TxType.income : TxType.expense;
    }

    final stagedTypeRaw = json['staged_type'];

    return StagedTransactionDraft(
      stagingId: json['staging_id']?.toString() ?? json['id']?.toString(),
      date: parsedDate,
      predictedType: parseType(json['predicted_type'] ?? json['type']),
      predictedCategory:
          (json['predicted_category'] ?? json['category'] ?? 'Misc').toString(),
      stagedType: stagedTypeRaw == null ? null : parseType(stagedTypeRaw),
      stagedCategory: json['staged_category']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description']?.toString(),
      accepted: (json['accepted'] as bool?) ?? true,
    );
  }

  static List<StagedTransactionDraft> fromUploadResponse(dynamic decoded) {
    dynamic source = decoded;

    if (decoded is Map<String, dynamic>) {
      source =
          decoded['transactions'] ??
          decoded['data'] ??
          decoded['results'] ??
          [];
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
      final dateValue =
          json['date'] ??
          json['transaction_date'] ??
          DateTime.now().toIso8601String();
      parsedDate = DateTime.parse(dateValue.toString());
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final rawType =
        (json['type'] ??
                json['predicted_type'] ??
                json['expected_type'] ??
                'Expense')
            .toString()
            .toLowerCase();
    final type = rawType.contains('income') ? TxType.income : TxType.expense;

    final rawAmount = json['amount'] ?? json['value'] ?? 0;
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount.toString().replaceAll(',', '')) ?? 0;

    return StagedTransactionDraft(
      stagingId: json['staging_id']?.toString() ?? json['id']?.toString(),
      date: parsedDate,
      predictedType: type,
      predictedCategory:
          (json['category'] ??
                  json['expected_category'] ??
                  json['predicted_category'] ??
                  'Misc')
              .toString(),
      stagedType: null,
      stagedCategory: null,
      amount: amount,
      description: (json['description'] ?? json['narration'])?.toString(),
      accepted: (json['accepted'] as bool?) ?? true,
    );
  }
}
