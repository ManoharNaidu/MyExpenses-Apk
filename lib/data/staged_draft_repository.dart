import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/storage/secure_storage.dart';
import '../models/staged_transaction_draft.dart';

class StagedDraftRepository {
  static String? _currentUserId;
  static bool _initialized = false;

  static final List<StagedTransactionDraft> _drafts = [];
  static final _streamController =
      StreamController<List<StagedTransactionDraft>>.broadcast();

  static String get _cacheKey =>
      'staged_drafts_cache_${_currentUserId ?? "guest"}';

  static List<StagedTransactionDraft> get currentDrafts =>
      List.unmodifiable(_drafts);

  static Stream<List<StagedTransactionDraft>> getDraftsStream() =>
      _streamController.stream;

  static void setCurrentUserId(String? userId) {
    if (_currentUserId == userId && _initialized) return;

    _currentUserId = userId;
    _initialized = false;
    _drafts.clear();
    _emitCurrent();

    if (userId == null) return;
    unawaited(_initialize());
  }

  static Future<void> _initialize() async {
    if (_currentUserId == null) return;
    await _loadFromCache();
    _initialized = true;
  }

  static Future<void> ensureInitialized() async {
    if (_currentUserId == null) return;
    if (_initialized) {
      _emitCurrent();
      return;
    }
    await _initialize();
  }

  static Future<void> saveDrafts(List<StagedTransactionDraft> drafts) async {
    _drafts
      ..clear()
      ..addAll(drafts);
    _emitCurrent();
    await _saveToCache();
  }

  static Future<void> upsertDrafts(List<StagedTransactionDraft> drafts) async {
    final byId = <String, StagedTransactionDraft>{
      for (final d in _drafts)
        if ((d.stagingId ?? '').isNotEmpty) d.stagingId!: d,
    };

    final withoutId = _drafts.where((d) => (d.stagingId ?? '').isEmpty).toList();

    for (final draft in drafts) {
      final id = draft.stagingId;
      if (id == null || id.isEmpty) {
        withoutId.add(draft);
      } else {
        byId[id] = draft;
      }
    }

    _drafts
      ..clear()
      ..addAll(byId.values)
      ..addAll(withoutId);
    _emitCurrent();
    await _saveToCache();
  }

  static Future<void> removeByStagingIds(Set<String> stagingIds) async {
    if (stagingIds.isEmpty) return;

    _drafts.removeWhere(
      (d) => d.stagingId != null && stagingIds.contains(d.stagingId),
    );
    _emitCurrent();
    await _saveToCache();
  }

  static Future<void> clear() async {
    _drafts.clear();
    _emitCurrent();
    if (_currentUserId == null) return;
    await SecureStorage.deleteKey(_cacheKey);
  }

  static Future<void> _loadFromCache() async {
    if (_currentUserId == null) return;

    try {
      final raw = await SecureStorage.readString(_cacheKey);
      if (raw == null || raw.isEmpty) {
        _drafts.clear();
        _emitCurrent();
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _drafts.clear();
        _emitCurrent();
        return;
      }

      _drafts
        ..clear()
        ..addAll(
          decoded
              .whereType<Map>()
              .map(
                (e) => StagedTransactionDraft.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(),
        );
      _emitCurrent();
    } catch (e) {
      debugPrint('❌ Failed to load staged drafts cache: $e');
      _drafts.clear();
      _emitCurrent();
    }
  }

  static Future<void> _saveToCache() async {
    if (_currentUserId == null) return;

    try {
      await SecureStorage.writeString(
        _cacheKey,
        jsonEncode(_drafts.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('❌ Failed to save staged drafts cache: $e');
    }
  }

  static void _emitCurrent() {
    if (_streamController.isClosed) return;
    _streamController.add(List.unmodifiable(_drafts));
  }

  static void dispose() {
    _streamController.close();
  }
}
