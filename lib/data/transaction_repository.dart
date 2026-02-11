import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../core/api/api_client.dart';

class TransactionRepository {
  static String? _currentUserId;
  static Timer? _pollingTimer;
  static final _streamController =
      StreamController<List<TransactionModel>>.broadcast();

  /// Set the current user ID for filtering transactions
  static void setCurrentUserId(String? userId) {
    _currentUserId = userId;
    debugPrint("🔑 TransactionRepository: Current user ID set to: $userId");

    // Restart polling when user changes
    if (userId != null) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  /// Start polling for transaction updates
  static void _startPolling() {
    _stopPolling(); // Stop any existing timer

    // Fetch immediately
    _fetchAndEmit();

    // Then poll every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchAndEmit();
    });

    debugPrint("📡 Started polling for transactions");
  }

  /// Stop polling
  static void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint("🛑 Stopped polling for transactions");
  }

  /// Fetch transactions and emit to stream
  static Future<void> _fetchAndEmit() async {
    try {
      final transactions = await fetchAll();
      _streamController.add(transactions);
    } catch (e) {
      debugPrint("❌ Error fetching transactions: $e");
      _streamController.addError(e);
    }
  }

  static Future<List<TransactionModel>> fetchAll() async {
    try {
      debugPrint("📥 Fetching all transactions from FastAPI");
      final response = await ApiClient.get("/transactions");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final transactions = data
            .map((json) => TransactionModel.fromJson(json))
            .toList();
        debugPrint("✅ Fetched ${transactions.length} transactions");
        return transactions;
      } else {
        debugPrint("❌ Failed to fetch transactions: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching transactions: $e");
      return [];
    }
  }

  static Future<List<TransactionModel>> fetchLast10() async {
    try {
      debugPrint("📥 Fetching last 10 transactions from FastAPI");
      final response = await ApiClient.get("/transactions?limit=10");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TransactionModel.fromJson(json)).toList();
      } else {
        debugPrint("❌ Failed to fetch transactions: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching transactions: $e");
      return [];
    }
  }

  static Future<void> add(TransactionModel tx) async {
    try {
      debugPrint("➕ Adding transaction via FastAPI");
      final response = await ApiClient.post("/transactions", tx.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Transaction added successfully");
        // Immediately fetch and update stream
        await _fetchAndEmit();
      } else {
        debugPrint(
          "❌ Failed to add transaction: ${response.statusCode} - ${response.body}",
        );
        throw Exception("Failed to add transaction: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error adding transaction: $e");
      rethrow;
    }
  }

  static Future<void> delete(String id) async {
    try {
      debugPrint("🗑️ Deleting transaction $id via FastAPI");
      final response = await ApiClient.delete("/transactions/$id");

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("✅ Transaction deleted successfully");
        // Immediately fetch and update stream
        await _fetchAndEmit();
      } else {
        debugPrint("❌ Failed to delete transaction: ${response.statusCode}");
        throw Exception("Failed to delete transaction");
      }
    } catch (e) {
      debugPrint("❌ Error deleting transaction: $e");
      rethrow;
    }
  }

  static Future<void> update(TransactionModel tx) async {
    try {
      debugPrint("✏️ Updating transaction ${tx.id} via FastAPI");
      final response = await ApiClient.put(
        "/transactions/${tx.id}",
        tx.toJson(),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Transaction updated successfully");
        // Immediately fetch and update stream
        await _fetchAndEmit();
      } else {
        debugPrint("❌ Failed to update transaction: ${response.statusCode}");
        throw Exception("Failed to update transaction");
      }
    } catch (e) {
      debugPrint("❌ Error updating transaction: $e");
      rethrow;
    }
  }

  static Stream<List<TransactionModel>> getTransactionsStream() {
    debugPrint("📡 Getting transaction stream");

    // Start polling if not already started
    if (_currentUserId != null && _pollingTimer == null) {
      _startPolling();
    }

    return _streamController.stream;
  }

  /// Manually refresh transactions and push latest state to listeners.
  static Future<void> refresh() async {
    await _fetchAndEmit();
  }

  /// Dispose resources
  static void dispose() {
    _stopPolling();
    _streamController.close();
  }
}
