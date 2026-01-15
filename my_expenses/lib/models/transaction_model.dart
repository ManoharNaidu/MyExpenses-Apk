import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 1)
enum TxType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  TxType type;

  @HiveField(3)
  String category;

  @HiveField(4)
  double amount;

  @HiveField(5)
  String notes;

  @HiveField(6)
  String paymentMethod; // Card/Cash

  TransactionModel({
    required this.id,
    required this.date,
    required this.type,
    required this.category,
    required this.amount,
    required this.notes,
    required this.paymentMethod,
  });
}
