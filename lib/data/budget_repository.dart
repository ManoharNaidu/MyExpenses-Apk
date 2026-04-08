import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/storage/secure_storage.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import 'transaction_repository.dart';

/// Status of a single category budget for a given month.
class BudgetStatus {
  final String category;
  final double limit;
  final double spent;

  double get remaining => limit - spent;
  double get percentage => limit > 0 ? (spent / limit).clamp(0.0, 9.99) : 0.0;
  bool get isOverBudget => spent > limit;
  bool get isWarning => percentage >= 0.8 && !isOverBudget;

  BudgetStatus({
    required this.category,
    required this.limit,
    required this.spent,
  });
}

/// Local-only budget persistence keyed by user ID.
///
/// Budgets are stored as a JSON array in [SecureStorage]. A budget entry with
/// a null `month_year` acts as a *default* that applies to any month for which
/// no specific override exists.
class BudgetRepository {
  BudgetRepository._();
  static final BudgetRepository _instance = BudgetRepository._();
  factory BudgetRepository() => _instance;

  static String? _userId;
  static List<BudgetModel> _budgets = [];
  static bool _loaded = false;

  static final _controller = StreamController<List<BudgetModel>>.broadcast();
  static Stream<List<BudgetModel>> get stream => _controller.stream;

  static String get _storageKey => 'budgets_${_userId ?? "guest"}';

  // ─── Lifecycle ──────────────────────────────────────────────

  static void setUserId(String? id) {
    if (_userId == id && _loaded) return;
    _userId = id;
    _loaded = false;
    _budgets = [];
    _emit();
  }

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    await _load();
  }

  // ─── Queries ────────────────────────────────────────────────

  /// Returns all raw budget entries (defaults + month-specific).
  static List<BudgetModel> get all => List.unmodifiable(_budgets);

  /// Returns effective budgets for [month], merging defaults with overrides.
  static List<BudgetModel> forMonth(DateTime month) {
    final key = _monthKey(month);

    // Month-specific entries
    final specific = <String, BudgetModel>{};
    // Default entries
    final defaults = <String, BudgetModel>{};

    for (final b in _budgets) {
      if (b.monthYear == null) {
        defaults[b.category] = b;
      } else if (_monthKey(b.monthYear!) == key) {
        specific[b.category] = b;
      }
    }

    // Merge: specific wins over default
    final merged = <String, BudgetModel>{...defaults, ...specific};
    return merged.values.toList()..sort((a, b) => a.category.compareTo(b.category));
  }

  /// Computes [BudgetStatus] for each budgeted category in [month],
  /// using actual spending from [TransactionRepository].
  static List<BudgetStatus> statusForMonth(DateTime month) {
    final budgets = forMonth(month);
    if (budgets.isEmpty) return [];

    final txs = TransactionRepository.currentTransactions;
    final spending = <String, double>{};

    for (final tx in txs) {
      if (tx.type != TxType.expense) continue;
      if (tx.date.year != month.year || tx.date.month != month.month) continue;
      spending[tx.category] = (spending[tx.category] ?? 0) + tx.amount;
    }

    return budgets.map((b) {
      return BudgetStatus(
        category: b.category,
        limit: b.monthlyLimit,
        spent: spending[b.category] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
  }

  // ─── Mutations ──────────────────────────────────────────────

  /// Set (create or update) a budget for [category].
  /// Pass [month] = null to set a default budget.
  static Future<void> setBudget(String category, double limit, {DateTime? month}) async {
    await ensureLoaded();

    final normalMonth = month != null ? DateTime(month.year, month.month, 1) : null;

    // Remove existing entry for same category + month
    _budgets.removeWhere((b) =>
        b.category == category &&
        ((b.monthYear == null && normalMonth == null) ||
            (b.monthYear != null &&
                normalMonth != null &&
                _monthKey(b.monthYear!) == _monthKey(normalMonth))));

    _budgets.add(BudgetModel(
      category: category,
      monthlyLimit: limit,
      monthYear: normalMonth,
    ));

    await _save();
    _emit();
  }

  /// Delete a budget entry for [category] in [month].
  /// Pass [month] = null to delete the default.
  static Future<void> deleteBudget(String category, {DateTime? month}) async {
    await ensureLoaded();

    final normalMonth = month != null ? DateTime(month.year, month.month, 1) : null;

    _budgets.removeWhere((b) =>
        b.category == category &&
        ((b.monthYear == null && normalMonth == null) ||
            (b.monthYear != null &&
                normalMonth != null &&
                _monthKey(b.monthYear!) == _monthKey(normalMonth))));

    await _save();
    _emit();
  }

  /// Delete ALL budgets.
  static Future<void> clearAll() async {
    _budgets.clear();
    await _save();
    _emit();
  }

  // ─── Persistence ────────────────────────────────────────────

  static Future<void> _load() async {
    try {
      final raw = await SecureStorage.readString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _budgets = list.map((e) => BudgetModel.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _budgets = [];
      }
    } catch (e) {
      debugPrint('⚠️ BudgetRepository._load error: $e');
      _budgets = [];
    }
    _loaded = true;
    _emit();
  }

  static Future<void> _save() async {
    try {
      final json = jsonEncode(_budgets.map((b) => b.toJson()).toList());
      await SecureStorage.writeString(_storageKey, json);
    } catch (e) {
      debugPrint('⚠️ BudgetRepository._save error: $e');
    }
  }

  static void _emit() {
    _controller.add(List.unmodifiable(_budgets));
  }

  static String _monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';
}
