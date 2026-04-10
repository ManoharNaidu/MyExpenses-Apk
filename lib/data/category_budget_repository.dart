import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/notifications/notification_service.dart';
import '../core/storage/secure_storage.dart';
import '../models/category_budget.dart';
import '../models/transaction_model.dart';

class CategoryBudgetRepository {
  static String? _currentUserId;
  static final List<CategoryBudget> _budgets = [];
  static bool _initialized = false;

  static final _streamController =
      StreamController<List<CategoryBudget>>.broadcast();

  static String get _cacheKey =>
      'category_budgets_${_currentUserId ?? "guest"}';

  static List<CategoryBudget> get currentBudgets => List.unmodifiable(_budgets);

  static Stream<List<CategoryBudget>> getBudgetsStream() =>
      _streamController.stream;

  static void setCurrentUserId(String? userId) {
    if (_currentUserId == userId && _initialized) return;
    _currentUserId = userId;
    _initialized = false;
    _budgets.clear();
    _emit();
    if (userId != null) {
      unawaited(ensureInitialized());
    }
  }

  static Future<void> ensureInitialized() async {
    if (_currentUserId == null || _initialized) return;
    await _loadFromCache();
    await fetchFromServer();
    _initialized = true;
  }

  static Future<void> _loadFromCache() async {
    if (_currentUserId == null) return;
    try {
      final raw = await SecureStorage.readString(_cacheKey);
      if (raw == null || raw.isEmpty) {
        _emit();
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _emit();
        return;
      }
      _budgets
        ..clear()
        ..addAll(
          decoded.whereType<Map>().map(
            (e) => CategoryBudget.fromJson(Map<String, dynamic>.from(e)),
          ),
        );
      _emit();
    } catch (e) {
      debugPrint('Failed to load category budget cache: $e');
      _budgets.clear();
      _emit();
    }
  }

  static Future<void> _saveCache() async {
    if (_currentUserId == null) return;
    await SecureStorage.writeString(
      _cacheKey,
      jsonEncode(_budgets.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> fetchFromServer() async {
    if (_currentUserId == null) return;
    final res = await ApiClient.get('/category-budgets');
    ApiClient.ensureSuccess(
      res,
      fallbackMessage: 'Failed to load category budgets',
    );
    if (res.body.isEmpty) {
      _budgets.clear();
      await _saveCache();
      _emit();
      return;
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) return;

    _budgets
      ..clear()
      ..addAll(
        decoded.whereType<Map>().map(
          (e) => CategoryBudget.fromJson(Map<String, dynamic>.from(e)),
        ),
      );
    _budgets.sort((a, b) => a.category.compareTo(b.category));

    await _saveCache();
    _emit();
  }

  static Future<void> saveToServer() async {
    if (_currentUserId == null) return;
    final payload = _budgets
        .map(
          (b) => {
            'category': b.category,
            'monthly_limit': b.monthlyLimit,
            'alerts_enabled': b.alertsEnabled,
            'enabled': b.enabled,
          },
        )
        .toList();

    final res = await ApiClient.put('/category-budgets', payload);
    ApiClient.ensureSuccess(
      res,
      fallbackMessage: 'Failed to save category budgets',
    );
    await _saveCache();
    _emit();
  }

  static Future<void> updateBudget(CategoryBudget budget) async {
    final existingIndex = _budgets.indexWhere(
      (b) => b.category == budget.category,
    );
    if (existingIndex == -1) {
      _budgets.add(budget);
    } else {
      _budgets[existingIndex] = budget;
    }

    _budgets.sort((a, b) => a.category.compareTo(b.category));
    await _saveCache();
    _emit();
  }

  static Future<void> deleteBudget(String category) async {
    _budgets.removeWhere((b) => b.category == category);
    await _saveCache();
    _emit();

    final encoded = Uri.encodeComponent(category);
    final res = await ApiClient.delete('/category-budgets/$encoded');
    ApiClient.ensureSuccess(
      res,
      fallbackMessage: 'Failed to delete category budget',
    );
  }

  static Future<void> checkThresholds(
    List<TransactionModel> txs,
    DateTime month,
  ) async {
    if (_currentUserId == null) return;

    final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final activeBudgets = _budgets.where((b) => b.enabled).toList();
    if (activeBudgets.isEmpty) return;

    for (final budget in activeBudgets) {
      final spent = txs
          .where(
            (t) =>
                t.type == TxType.expense &&
                t.category == budget.category &&
                t.date.year == month.year &&
                t.date.month == month.month,
          )
          .fold<double>(0, (sum, tx) => sum + tx.amount);
      if (budget.monthlyLimit <= 0) continue;

      final ratio = spent / budget.monthlyLimit;
      final key80 =
          'budget_alerted_80_${budget.category.toLowerCase()}_$monthKey';
      final key100 =
          'budget_alerted_100_${budget.category.toLowerCase()}_$monthKey';

      if (ratio >= 0.8) {
        final seen80 = await SecureStorage.readString(key80);
        if (seen80 != 'true') {
          await SecureStorage.writeString(key80, 'true');
        }
      }

      if (ratio >= 1.0 && budget.alertsEnabled) {
        final seen100 = await SecureStorage.readString(key100);
        if (seen100 != 'true') {
          await SecureStorage.writeString(key100, 'true');
          await NotificationService.show(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            title: 'Budget exceeded',
            body:
                '${budget.category}: ${spent.toStringAsFixed(2)} spent of ${budget.monthlyLimit.toStringAsFixed(2)}',
          );
        }
      }
    }
  }

  static void _emit() {
    if (_streamController.isClosed) return;
    _streamController.add(List.unmodifiable(_budgets));
  }
}
