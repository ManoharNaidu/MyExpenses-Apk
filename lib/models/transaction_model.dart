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
  });

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
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      // Don't send user_id - backend will extract it from JWT token
      'date': date.toIso8601String().split('T')[0], // date only (YYYY-MM-DD)
      'description': description,
      'notes': notes,
      'type': type == TxType.income ? 'income' : 'expense',
      'category': category,
      'amount': amount,
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
