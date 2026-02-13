import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = "access_token";

  static Future<void> saveToken(String token) async {
    debugPrint("💾 Saving token: ${token.substring(0, 20)}...");
    await _storage.write(key: _key, value: token);
    debugPrint("✅ Token saved successfully");
  }

  static Future<String?> readToken() async {
    final token = await _storage.read(key: _key);
    debugPrint(
      "📖 Reading token: ${token != null ? '${token.substring(0, 20)}...' : 'null'}",
    );
    return token;
  }

  static Future<void> clear() async {
    debugPrint("🗑️ Clearing token");
    await _storage.delete(key: _key);
  }

  static Future<void> writeString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> readString(String key) async {
    return _storage.read(key: key);
  }

  static Future<void> deleteKey(String key) async {
    await _storage.delete(key: key);
  }
}
