import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = "access_token";

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _key, value: token);
  }

  static Future<String?> readToken() async {
    return _storage.read(key: _key);
  }

  static Future<void> clear() async {
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
