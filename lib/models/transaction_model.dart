enum TxType { income, expense }

TxType _parseTxType(dynamic rawType) {
  final value = (rawType ?? '').toString().toLowerCase().trim();
  if (value == 'income' || value == 'credit') {
    return TxType.income;
  }
  return TxType.expense;
}

class TransactionModel {
  String? id;
  String? userId;
  DateTime date;
  String? description;
  String? notes;
  TxType type;
  String category;
  double amount;
  String? recurringId;
  bool repeatMonthly;
  List<String> tags;

  TransactionModel({
    this.id,
    this.userId,
    required this.date,
    this.description,
    this.notes,
    required this.type,
    required this.category,
    required this.amount,
    this.recurringId,
    this.repeatMonthly = false,
    this.tags = const [],
  });

  static List<String> extractTags(String? text) {
    if (text == null || text.isEmpty) return const [];
    final regex = RegExp(r'#(\w+)');
    final tags = regex
        .allMatches(text)
        .map((m) => (m.group(1) ?? '').toLowerCase())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return tags;
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date']);
    return TransactionModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      date: date,
      description: json['description']?.toString(),
      notes: (json['notes'] ?? json['description'])?.toString(),
      type: _parseTxType(json['type']),
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      recurringId: json['recurring_id']?.toString(),
      repeatMonthly: (json['repeat_monthly'] as bool?) ?? false,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString().toLowerCase())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    String? sanitizeText(String? value, {int max = 2000}) {
      if (value == null) return null;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return trimmed.length <= max ? trimmed : trimmed.substring(0, max);
    }

    final safeDescription = sanitizeText(description, max: 2000);
    final safeNotes = sanitizeText(notes, max: 2000);

    final map = {
      // Don't send user_id - backend will extract it from JWT token
      'date': date.toIso8601String(),
      'description': safeDescription,
      'notes': safeNotes,
      'type': type == TxType.income ? 'income' : 'expense',
      'category': category,
      'amount': amount,
      'tags': tags,
    };
    if (id != null) {
      map['id'] = id;
    }
    if (recurringId != null && recurringId!.trim().isNotEmpty) {
      map['recurring_id'] = recurringId;
    }
    if (repeatMonthly) {
      map['repeat_monthly'] = true;
    }
    return map;
  }
}
