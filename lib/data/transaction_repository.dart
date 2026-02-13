import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/notifications/notification_service.dart';
import '../core/storage/secure_storage.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  static const int pageSize = 10;

  static String? _currentUserId;
  static bool _initialized = false;
  static bool _isLoading = false;
  static bool _hasMore = true;
  static bool _isOnline = true;
  static int _offset = 0;

  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;

  static final List<TransactionModel> _transactions = [];

  static final _streamController =
      StreamController<List<TransactionModel>>.broadcast();

  static String get _cacheKey => 'tx_cache_${_currentUserId ?? "guest"}';

  static bool get hasMore => _hasMore;
  static bool get isLoading => _isLoading;
  static bool get isOnline => _isOnline;
  static List<TransactionModel> get currentTransactions =>
      List.unmodifiable(_transactions);

  /// Set current user and bootstrap repository state.
  static void setCurrentUserId(String? userId) {
    if (_currentUserId == userId && _initialized) return;

    _currentUserId = userId;
    _initialized = false;
    _offset = 0;
    _hasMore = true;
    _transactions.clear();

    if (userId == null) {
      _stopConnectivityListener();
      _emitCurrent();
      return;
    }

    unawaited(_initialize());
  }

  static Future<void> _initialize() async {
    if (_currentUserId == null) return;

    await _startConnectivityListener();
    await _loadFromCache();

    _initialized = true;
    await loadInitial(forceRefresh: _transactions.isEmpty);
  }

  static Stream<List<TransactionModel>> getTransactionsStream() {
    if (_currentUserId != null && !_initialized) {
      unawaited(_initialize());
    }
    return _streamController.stream;
  }

  static Future<void> ensureInitialized() async {
    if (_currentUserId == null) return;
    if (_initialized) {
      _emitCurrent();
      return;
    }
    await _initialize();
  }

  static Future<void> _startConnectivityListener() async {
    await _connectivitySubscription?.cancel();

    final connectivity = Connectivity();
    final current = await connectivity.checkConnectivity();
    _isOnline = _hasConnection(current);

    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final wasOnline = _isOnline;
      _isOnline = _hasConnection(results);

      debugPrint('🌐 Connectivity changed. Online=$_isOnline');

      if (!wasOnline && _isOnline) {
        // Back online: refresh first page so we don't keep stale state forever.
        unawaited(loadInitial(forceRefresh: true));
      }
    });
  }

  static bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  static void _stopConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  static Future<void> _loadFromCache() async {
    if (_currentUserId == null) return;

    try {
      final raw = await SecureStorage.readString(_cacheKey);
      if (raw == null || raw.isEmpty) {
        _emitCurrent();
        return;
      }

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final List<dynamic> items = (decoded['transactions'] as List?) ?? [];

      _transactions
        ..clear()
        ..addAll(
          items
              .whereType<Map<String, dynamic>>()
              .map(TransactionModel.fromJson)
              .toList(),
        );

      _offset = _transactions.length;
      _hasMore =
          (decoded['has_more'] as bool?) ?? _transactions.length >= pageSize;

      debugPrint('💾 Loaded ${_transactions.length} cached transactions');
      _emitCurrent();
    } catch (e) {
      debugPrint('❌ Failed to load tx cache: $e');
      _transactions.clear();
      _offset = 0;
      _hasMore = true;
      _emitCurrent();
    }
  }

  static Future<void> _saveToCache() async {
    if (_currentUserId == null) return;

    try {
      final payload = {
        'updated_at': DateTime.now().toIso8601String(),
        'has_more': _hasMore,
        'transactions': _transactions.map((e) => e.toJson()).toList(),
      };
      await SecureStorage.writeString(_cacheKey, jsonEncode(payload));
      debugPrint('💾 Cached ${_transactions.length} transactions');
    } catch (e) {
      debugPrint('❌ Failed to save tx cache: $e');
    }
  }

  static void _emitCurrent() {
    _streamController.add(List.unmodifiable(_transactions));
  }

  static Future<List<TransactionModel>> _fetchPage({
    required int offset,
    int limit = pageSize,
  }) async {
    final response = await ApiClient.get(
      '/transactions?limit=$limit&offset=$offset',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch transactions: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data
        .whereType<Map<String, dynamic>>()
        .map(TransactionModel.fromJson)
        .toList();
  }

  /// Loads first page (10 records), optionally forcing network refresh.
  static Future<void> loadInitial({bool forceRefresh = false}) async {
    if (_currentUserId == null || _isLoading) return;

    if (!forceRefresh && _transactions.isNotEmpty) {
      _emitCurrent();
      return;
    }

    if (!_isOnline) {
      _emitCurrent();
      return;
    }

    _isLoading = true;
    try {
      final firstPage = await _fetchPage(offset: 0, limit: pageSize);
      _transactions
        ..clear()
        ..addAll(firstPage);
      _offset = _transactions.length;
      _hasMore = firstPage.length == pageSize;
      _emitCurrent();
      await _saveToCache();
    } catch (e) {
      debugPrint('❌ loadInitial error: $e');
      _emitCurrent(); // keep cached data visible instead of crashing.
    } finally {
      _isLoading = false;
    }
  }

  /// Loads the next page (next 10 records) and appends it.
  static Future<void> loadMore() async {
    if (_currentUserId == null || _isLoading || !_hasMore || !_isOnline) return;

    _isLoading = true;
    try {
      final page = await _fetchPage(offset: _offset, limit: pageSize);

      if (page.isEmpty) {
        _hasMore = false;
      } else {
        _transactions.addAll(page);
        _offset = _transactions.length;
        _hasMore = page.length == pageSize;
      }

      _emitCurrent();
      await _saveToCache();
    } catch (e) {
      debugPrint('❌ loadMore error: $e');
      _emitCurrent();
    } finally {
      _isLoading = false;
    }
  }

  /// Fetches all pages once (non-polling) for one-off operations like export.
  static Future<List<TransactionModel>> fetchAll() async {
    if (_currentUserId == null) return [];

    if (!_isOnline) {
      return List.unmodifiable(_transactions);
    }

    try {
      final all = <TransactionModel>[];
      var offset = 0;

      while (true) {
        final page = await _fetchPage(offset: offset, limit: pageSize);
        if (page.isEmpty) break;
        all.addAll(page);
        if (page.length < pageSize) break;
        offset += pageSize;
      }

      _transactions
        ..clear()
        ..addAll(all);
      _offset = _transactions.length;
      _hasMore = false;
      _emitCurrent();
      await _saveToCache();

      return List.unmodifiable(all);
    } catch (e) {
      debugPrint('❌ fetchAll error: $e');
      return List.unmodifiable(_transactions);
    }
  }

  static Future<void> add(TransactionModel tx) async {
    final response = await ApiClient.post('/transactions', tx.toJson());
    if (response.statusCode == 200 || response.statusCode == 201) {
      await _refreshLoadedWindow();
      await NotificationService.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'Transaction added',
        body: '${tx.category} • ${tx.amount.toStringAsFixed(2)} saved',
      );
      return;
    }
    throw Exception('Failed to add transaction: ${response.body}');
  }

  static Future<void> delete(String id) async {
    final response = await ApiClient.delete('/transaction/$id');
    if (response.statusCode == 200 || response.statusCode == 204) {
      await _refreshLoadedWindow();
      await NotificationService.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'Transaction deleted',
        body: 'A transaction was removed successfully',
      );
      return;
    }
    throw Exception('Failed to delete transaction: ${response.body}');
  }

  static Future<void> update(TransactionModel tx) async {
    final response = await ApiClient.put('/transactions/${tx.id}', tx.toJson());
    if (response.statusCode == 200) {
      await _refreshLoadedWindow();
      return;
    }
    throw Exception('Failed to update transaction: ${response.body}');
  }

  /// Refreshes currently loaded window size without switching back to polling.
  static Future<void> _refreshLoadedWindow() async {
    final loadedCount = _transactions.isEmpty ? pageSize : _transactions.length;
    if (!_isOnline) {
      _emitCurrent();
      return;
    }

    _isLoading = true;
    try {
      final refreshed = await _fetchPage(offset: 0, limit: loadedCount);
      _transactions
        ..clear()
        ..addAll(refreshed);

      _offset = _transactions.length;
      _hasMore = refreshed.length == loadedCount;

      _emitCurrent();
      await _saveToCache();
    } catch (e) {
      debugPrint('❌ refresh window error: $e');
      _emitCurrent();
    } finally {
      _isLoading = false;
    }
  }

  /// Manual refresh entrypoint.
  static Future<void> refresh() async {
    await _refreshLoadedWindow();
  }

  static void clearUserCache() {
    if (_currentUserId == null) return;
    unawaited(SecureStorage.deleteKey(_cacheKey));
  }

  /// Dispose resources.
  static void dispose() {
    _stopConnectivityListener();
    _streamController.close();
  }
}
