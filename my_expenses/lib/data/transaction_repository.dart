import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import 'supabase_client.dart';

class TransactionRepository {
  static final SupabaseClient _client = SupabaseClientManager.client;

  static Future<List<TransactionModel>> fetchAll() async {
    final response = await _client
        .from('transactions')
        .select()
        .order('date', ascending: false);

    return response.map((json) => TransactionModel.fromJson(json)).toList();
  }

  static Future<List<TransactionModel>> fetchLast10() async {
    final response = await _client
        .from('transactions')
        .select()
        .order('date', ascending: false)
        .limit(10);

    return response.map((json) => TransactionModel.fromJson(json)).toList();
  }

  static Future<void> add(TransactionModel tx) async {
    await _client.from('transactions').insert(tx.toJson());
  }

  static Future<void> delete(String id) async {
    await _client.from('transactions').delete().eq('id', id);
  }

  static Future<void> update(TransactionModel tx) async {
    await _client.from('transactions').update(tx.toJson()).eq('id', tx.id!);
  }

  static Stream<List<TransactionModel>> getTransactionsStream() {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('date', ascending: false)
        .map(
          (data) =>
              data.map((json) => TransactionModel.fromJson(json)).toList(),
        );
  }
}
