import 'package:intl/intl.dart';

enum TxType { income, expense }

class TransactionModel {
  String? id;
  String? userId;
  DateTime date;
  DateTime? originalDate;
  String? description;
  TxType type;
  String category;
  double amount;
  String? month;
  String? week;
  String source;
  DateTime? createdAt;

  TransactionModel({
    this.id,
    this.userId,
    required this.date,
    this.originalDate,
    this.description,
    required this.type,
    required this.category,
    required this.amount,
    this.month,
    this.week,
    required this.source,
    this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      originalDate: json['original_date'] != null
          ? DateTime.parse(json['original_date'])
          : null,
      description: json['description'] as String?,
      type: json['type'] == 'Income' ? TxType.income : TxType.expense,
      category: json['category'],
      amount: json['amount'],
      month: json['month'],
      week: json['week'],
      source: json['source'] ?? 'app',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0], // date only
      'original_date': originalDate?.toIso8601String().split('T')[0],
      'description': description,
      'type': type == TxType.income ? 'Income' : 'Expense',
      'category': category,
      'amount': amount,
      'month': month,
      'week': week,
      'source': source,
      'created_at': createdAt != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss+00').format(createdAt!.toUtc())
          : null,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
