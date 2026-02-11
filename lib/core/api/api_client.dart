import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../storage/secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static String get _baseUrl => dotenv.env['API_URL'] ?? '';

  static Future<http.Response> post(String path, Map body) async {
    try {
      final token = await SecureStorage.readToken();

      if (token == null) {
        debugPrint("❌ No auth token found!");
        return http.Response('{"error": "No authentication token"}', 401);
      }

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final url = "$_baseUrl$path";
      debugPrint("🌐 POST $url");
      debugPrint("🔑 Token: ${token.substring(0, 20)}...");
      debugPrint("📦 Body: ${jsonEncode(body)}");

      final response = await http
          .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint("⏱️ Request timeout after 30 seconds");
              return http.Response('{"error": "Request timeout"}', 408);
            },
          );

      debugPrint("📥 Response ${response.statusCode}: ${response.body}");
      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ API Error: $e");
      debugPrint("📍 Stack trace: $stackTrace");
      // Return error response instead of throwing
      return http.Response('{"error": "$e"}', 500);
    }
  }

  static Future<http.Response> get(String path) async {
    try {
      final token = await SecureStorage.readToken();

      if (token == null) {
        debugPrint("❌ No auth token found!");
        return http.Response('{"error": "No authentication token"}', 401);
      }

      final url = "$_baseUrl$path";

      debugPrint("🌐 GET $url");
      debugPrint("🔑 Token: ${token.substring(0, 20)}...");

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint("⏱️ Request timeout after 30 seconds");
              return http.Response('{"error": "Request timeout"}', 408);
            },
          );

      debugPrint("📥 Response ${response.statusCode}: ${response.body}");
      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ API Error: $e");
      debugPrint("📍 Stack trace: $stackTrace");
      // Return error response instead of throwing
      return http.Response('{"error": "$e"}', 500);
    }
  }

  static Future<http.Response> put(String path, Map body) async {
    try {
      final token = await SecureStorage.readToken();

      if (token == null) {
        debugPrint("❌ No auth token found!");
        return http.Response('{"error": "No authentication token"}', 401);
      }

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final url = "$_baseUrl$path";
      debugPrint("🌐 PUT $url");
      debugPrint("🔑 Token: ${token.substring(0, 20)}...");
      debugPrint("📦 Body: ${jsonEncode(body)}");

      final response = await http
          .put(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint("⏱️ Request timeout after 30 seconds");
              return http.Response('{"error": "Request timeout"}', 408);
            },
          );

      debugPrint("📥 Response ${response.statusCode}: ${response.body}");
      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ API Error: $e");
      debugPrint("📍 Stack trace: $stackTrace");
      // Return error response instead of throwing
      return http.Response('{"error": "$e"}', 500);
    }
  }

  static Future<http.Response> delete(String path) async {
    try {
      final token = await SecureStorage.readToken();

      if (token == null) {
        debugPrint("❌ No auth token found!");
        return http.Response('{"error": "No authentication token"}', 401);
      }

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final url = "$_baseUrl$path";
      debugPrint("🌐 DELETE $url");
      debugPrint("🔑 Token: ${token.substring(0, 20)}...");

      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint("⏱️ Request timeout after 30 seconds");
              return http.Response('{"error": "Request timeout"}', 408);
            },
          );

      debugPrint("📥 Response ${response.statusCode}: ${response.body}");
      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ API Error: $e");
      debugPrint("📍 Stack trace: $stackTrace");
      // Return error response instead of throwing
      return http.Response('{"error": "$e"}', 500);
    }
  }
}
