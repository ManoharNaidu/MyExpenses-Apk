import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/notifications/notification_service.dart';
import '../core/storage/secure_storage.dart';
import '../models/outbox_operation.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  static const int pageSize = 10;

  static String? _currentUserId;
  static bool _initialized = false;
  static bool _isLoading = false;
  static bool _hasMore = true;
  static bool _isOnline = true;
  static bool _isSyncing = false;
  static int _offset = 0;

  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;

  static final List<TransactionModel> _transactions = [];
  static final List<OutboxOperation> _outbox = [];

  static final _streamController =
      StreamController<List<TransactionModel>>.broadcast();
  static final _outboxCountController = StreamController<int>.broadcast();
  static final _syncingController = StreamController<bool>.broadcast();

  static String get _cacheKey => 'tx_cache_${_currentUserId ?? "guest"}';
  static String get _outboxKey => 'tx_outbox_${_currentUserId ?? "guest"}';

  static bool get hasMore => _hasMore;
  static bool get isLoading => _isLoading;
  static bool get isOnline => _isOnline;
  static bool get isSyncing => _isSyncing;
  static int get pendingOutboxCount => _outbox.length;
  static List<TransactionModel> get currentTransactions =>
      List.unmodifiable(_transactions);
  static Stream<int> getOutboxCountStream() => _outboxCountController.stream;
  static Stream<bool> getSyncingStream() => _syncingController.stream;

  /// Set current user and bootstrap repository state.
  static void setCurrentUserId(String? userId) {
    if (_currentUserId == userId && _initialized) return;

    _currentUserId = userId;
    _initialized = false;
    _offset = 0;
    _hasMore = true;
    _isSyncing = false;
    _transactions.clear();
    _outbox.clear();
    _emitOutboxCount();
    _emitSyncing();

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
    await _loadOutbox();

    _initialized = true;
    await loadInitial(forceRefresh: _transactions.isEmpty);
    unawaited(syncPendingOperations());
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
        // Back online: run queued sync then refresh.
        unawaited(() async {
          await syncPendingOperations();
          await loadInitial(forceRefresh: true);
        }());
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

  static Future<void> _loadOutbox() async {
    if (_currentUserId == null) return;

    try {
      final raw = await SecureStorage.readString(_outboxKey);
      if (raw == null || raw.isEmpty) {
        _outbox.clear();
        _emitOutboxCount();
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _outbox.clear();
        _emitOutboxCount();
        return;
      }

      _outbox
        ..clear()
        ..addAll(
          decoded
              .whereType<Map>()
              .map((e) => OutboxOperation.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
        );
      _emitOutboxCount();
    } catch (e) {
      debugPrint('❌ Failed to load outbox cache: $e');
      _outbox.clear();
      _emitOutboxCount();
    }
  }

  static Future<void> _saveOutbox() async {
    if (_currentUserId == null) return;

    try {
      await SecureStorage.writeString(
        _outboxKey,
        jsonEncode(_outbox.map((e) => e.toJson()).toList()),
      );
      _emitOutboxCount();
    } catch (e) {
      debugPrint('❌ Failed to save outbox cache: $e');
    }
  }

  static void _emitCurrent() {
    _streamController.add(List.unmodifiable(_transactions));
  }

  static void _emitOutboxCount() {
    if (_outboxCountController.isClosed) return;
    _outboxCountController.add(_outbox.length);
  }

  static void _emitSyncing() {
    if (_syncingController.isClosed) return;
    _syncingController.add(_isSyncing);
  }

  static Future<List<TransactionModel>> _fetchPage({
    required int offset,
    int limit = pageSize,
  }) async {
    final response = await ApiClient.get(
      '/transactions?limit=$limit&offset=$offset',
    );
    ApiClient.ensureSuccess(
      response,
      fallbackMessage: 'Failed to fetch transactions',
    );

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
      _hasMore = firstPage.length >= pageSize;
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
        _hasMore = page.length >= pageSize;
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
    final localId = tx.id ?? 'local_${DateTime.now().microsecondsSinceEpoch}';
    final localTx = TransactionModel(
      id: localId,
      userId: tx.userId,
      date: tx.date,
      description: tx.description,
      type: tx.type,
      category: tx.category,
      amount: tx.amount,
    );

    _transactions.insert(0, localTx);
    _offset = _transactions.length;
    _emitCurrent();
    await _saveToCache();

    final payload = Map<String, dynamic>.from(localTx.toJson())..remove('id');
    _outbox.add(
      OutboxOperation(
        id: OutboxOperation.generateId(),
        type: OutboxOperationType.createTransaction,
        entityId: localId,
        payload: payload,
        createdAt: DateTime.now(),
      ),
    );
    await _saveOutbox();
    unawaited(syncPendingOperations());

    await NotificationService.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'Transaction added',
      body: '${tx.category} • ${tx.amount.toStringAsFixed(2)} saved',
    );
  }

  static Future<void> delete(String id) async {
    final beforeCount = _transactions.length;
    _transactions.removeWhere((tx) => tx.id == id);
    final didRemove = _transactions.length < beforeCount;

    if (didRemove) {
      _offset = _transactions.length;
      _emitCurrent();
      await _saveToCache();
    }

    if (_isLocalId(id)) {
      _outbox.removeWhere(
        (op) => op.entityId == id &&
            (op.type == OutboxOperationType.createTransaction ||
                op.type == OutboxOperationType.updateTransaction),
      );
    } else {
      _outbox.add(
        OutboxOperation(
          id: OutboxOperation.generateId(),
          type: OutboxOperationType.deleteTransaction,
          entityId: id,
          payload: null,
          createdAt: DateTime.now(),
        ),
      );
    }
    await _saveOutbox();
    unawaited(syncPendingOperations());

    await NotificationService.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'Transaction deleted',
      body: 'A transaction was removed successfully',
    );
  }

  static Future<void> update(TransactionModel tx) async {
    if (tx.id != null) {
      final index = _transactions.indexWhere((item) => item.id == tx.id);
      if (index != -1) {
        _transactions[index] = tx;
        _emitCurrent();
        await _saveToCache();
      }
    }

    final txId = tx.id;
    if (txId == null) return;

    final payload = Map<String, dynamic>.from(tx.toJson())..remove('id');
    if (_isLocalId(txId)) {
      final idx = _outbox.indexWhere(
        (op) =>
            op.type == OutboxOperationType.createTransaction &&
            op.entityId == txId,
      );
      if (idx != -1) {
        _outbox[idx] = _outbox[idx].copyWith(payload: payload);
      }
    } else {
      _outbox.add(
        OutboxOperation(
          id: OutboxOperation.generateId(),
          type: OutboxOperationType.updateTransaction,
          entityId: txId,
          payload: payload,
          createdAt: DateTime.now(),
        ),
      );
    }
    await _saveOutbox();
    unawaited(syncPendingOperations());
  }

  static Future<void> enqueueStagingConfirmation(
    List<Map<String, dynamic>> confirmations,
  ) async {
    if (confirmations.isEmpty) return;

    _outbox.add(
      OutboxOperation(
        id: OutboxOperation.generateId(),
        type: OutboxOperationType.confirmStaging,
        payload: confirmations,
        createdAt: DateTime.now(),
      ),
    );
    await _saveOutbox();
    unawaited(syncPendingOperations());
  }

  static Future<void> syncPendingOperations() async {
    if (_currentUserId == null || !_isOnline || _isSyncing || _outbox.isEmpty) {
      return;
    }

    _isSyncing = true;
    _emitSyncing();

    try {
      var hadSuccess = false;

      while (_outbox.isNotEmpty && _isOnline) {
        final op = _outbox.first;
        try {
          await _executeOutboxOperation(op);
          hadSuccess = true;
          _outbox.removeAt(0);
          await _saveOutbox();
        } catch (e) {
          _outbox[0] = op.copyWith(
            retryCount: op.retryCount + 1,
            lastError: e.toString(),
          );
          await _saveOutbox();
          break;
        }
      }

      if (hadSuccess) {
        await _refreshLoadedWindow();
      }
    } finally {
      _isSyncing = false;
      _emitSyncing();
    }
  }

  static Future<void> _executeOutboxOperation(OutboxOperation op) async {
    switch (op.type) {
      case OutboxOperationType.createTransaction:
        final res = await ApiClient.post('/transactions', op.payload);
        ApiClient.ensureSuccess(
          res,
          fallbackMessage: 'Failed to sync transaction create',
        );
        final createdId = _extractCreatedId(res.body);
        if (createdId != null && op.entityId != null) {
          _replaceLocalTransactionId(op.entityId!, createdId);
        }
        break;
      case OutboxOperationType.updateTransaction:
        final id = op.entityId;
        if (id == null || id.isEmpty) return;
        final res = await ApiClient.put(
          '/transactions/$id',
          Map<String, dynamic>.from(op.payload as Map),
        );
        ApiClient.ensureSuccess(
          res,
          fallbackMessage: 'Failed to sync transaction update',
        );
        break;
      case OutboxOperationType.deleteTransaction:
        final id = op.entityId;
        if (id == null || id.isEmpty) return;
        final res = await ApiClient.delete('/transactions/$id');
        ApiClient.ensureSuccess(
          res,
          fallbackMessage: 'Failed to sync transaction delete',
        );
        break;
      case OutboxOperationType.confirmStaging:
        final raw = op.payload;
        final payload = (raw is List ? raw : const <dynamic>[])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where(
              (item) =>
                  (item['id']?.toString().trim().isNotEmpty ?? false) &&
                  (item['final_type']?.toString().trim().isNotEmpty ?? false) &&
                  (item['final_category']?.toString().trim().isNotEmpty ?? false),
            )
            .toList();
        if (payload.isEmpty) return;
        final res = await ApiClient.post('/confirm-staging-transactions', payload);
        ApiClient.ensureSuccess(
          res,
          fallbackMessage: 'Failed to sync staged confirmations',
        );
        break;
    }
  }

  static bool _isLocalId(String id) => id.startsWith('local_');

  static String? _extractCreatedId(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final id = decoded['id'] ?? (decoded['transaction']?['id']);
        if (id != null) return id.toString();
      }
    } catch (_) {
      // ignore parse errors
    }
    return null;
  }

  static void _replaceLocalTransactionId(String localId, String remoteId) {
    final txIndex = _transactions.indexWhere((t) => t.id == localId);
    if (txIndex != -1) {
      _transactions[txIndex].id = remoteId;
      _emitCurrent();
      unawaited(_saveToCache());
    }

    for (var i = 0; i < _outbox.length; i++) {
      final op = _outbox[i];
      if (op.entityId == localId) {
        _outbox[i] = op.copyWith(entityId: remoteId);
      }
    }
    unawaited(_saveOutbox());
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
      _hasMore = refreshed.length >= loadedCount;

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
    unawaited(SecureStorage.deleteKey(_outboxKey));
  }

  /// Dispose resources.
  static void dispose() {
    _stopConnectivityListener();
    _streamController.close();
    _outboxCountController.close();
    _syncingController.close();
  }
}
