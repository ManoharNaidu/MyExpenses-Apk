import 'package:hive/hive.dart';
import '../data/hive_boxes.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  static Box<TransactionModel> get _box => Hive.box<TransactionModel>(HiveBoxes.transactions);

  static List<TransactionModel> all() {
    final items = _box.values.toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  static Future<void> add(TransactionModel tx) async {
    await _box.put(tx.id, tx);
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
  }

  static Future<void> update(TransactionModel tx) async {
    await _box.put(tx.id, tx);
  }
}
