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
  TxType type;
  String category;
  double amount;

  TransactionModel({
    this.id,
    this.userId,
    required this.date,
    this.description,
    required this.type,
    required this.category,
    required this.amount,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date']);
    return TransactionModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      date: date,
      description: json['description'] as String?,
      type: _parseTxType(json['type']),
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      // Don't send user_id - backend will extract it from JWT token
      'date': date.toIso8601String().split('T')[0], // date only (YYYY-MM-DD)
      'description': description,
      'type': type == TxType.income ? 'income' : 'expense',
      'category': category,
      'amount': amount,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
