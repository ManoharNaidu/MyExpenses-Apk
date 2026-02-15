import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../storage/secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static String get _baseUrl => dotenv.env['API_URL'] ?? '';
  static const String genericUnexpectedMessage =
      'Something unexpected happened. Please try again.';

  static bool isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  static String extractErrorMessage(
    http.Response response, {
    String fallbackMessage = genericUnexpectedMessage,
  }) {
    if (response.body.isEmpty) return fallbackMessage;

    try {
      final parsed = jsonDecode(response.body);
      if (parsed is Map<String, dynamic>) {
        final message =
            parsed['message'] ?? parsed['detail'] ?? parsed['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      // fallback below
    }

    final raw = response.body.trim();
    return raw.isEmpty ? fallbackMessage : raw;
  }

  static void ensureSuccess(
    http.Response response, {
    String fallbackMessage = genericUnexpectedMessage,
  }) {
    if (isSuccess(response.statusCode)) return;
    throw ApiException(
      extractErrorMessage(response, fallbackMessage: fallbackMessage),
      statusCode: response.statusCode,
    );
  }

  static bool _isRetryableStatus(int statusCode) {
    return statusCode == 408 ||
        statusCode == 429 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  static Future<http.Response> _withRetry(
    Future<http.Response> Function() request,
  ) async {
    const maxAttempts = 2;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await request();
        if (!_isRetryableStatus(response.statusCode) || attempt == maxAttempts) {
          return response;
        }

        debugPrint(
          '♻️ Retrying request after status ${response.statusCode} (attempt $attempt/$maxAttempts)',
        );
      } on TimeoutException catch (_) {
        if (attempt == maxAttempts) rethrow;
        debugPrint('♻️ Retrying request after timeout (attempt $attempt/$maxAttempts)');
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        debugPrint('♻️ Retrying request after network error: $e');
      }

      await Future.delayed(const Duration(milliseconds: 900));
    }

    return http.Response('{"error": "Retry failed"}', 500);
  }

  static Future<http.Response> post(
    String path,
    Object? body, {
    bool requiresAuth = true,
  }) async {
    try {
      final token = requiresAuth ? await SecureStorage.readToken() : null;

      if (requiresAuth && token == null) {
        debugPrint("❌ No auth token found!");
        return http.Response('{"error": "No authentication token"}', 401);
      }

      final headers = <String, String>{"Content-Type": "application/json"};
      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }

      final url = "$_baseUrl$path";
      debugPrint("🌐 POST $url");
      if (token != null) {
        debugPrint("🔑 Token: ${token.substring(0, 20)}...");
      } else {
        debugPrint("🔓 Public request (no token)");
      }
      debugPrint("📦 Body: ${jsonEncode(body)}");

      final response = await _withRetry(
        () => http
            .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                debugPrint("⏱️ Request timeout after 30 seconds");
                return http.Response('{"error": "Request timeout"}', 408);
              },
            ),
      );

      debugPrint("📥 Response ${response.statusCode}: ${response.body}");
      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ API Error: $e");
      debugPrint("📍 Stack trace: $stackTrace");
      return http.Response('{"message": "$genericUnexpectedMessage"}', 500);
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

      final response = await _withRetry(
        () => http
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
            ),
      );

      debugPrint("📥 Response ${response.statusCode}: ${response.body}");
      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ API Error: $e");
      debugPrint("📍 Stack trace: $stackTrace");
      return http.Response('{"message": "$genericUnexpectedMessage"}', 500);
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

      final response = await _withRetry(
        () => http
            .put(Uri.parse(url), headers: headers, body: jsonEncode(body))
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                debugPrint("⏱️ Request timeout after 30 seconds");
                return http.Response('{"error": "Request timeout"}', 408);
              },
            ),
      );

      debugPrint("📥 Response ${response.statusCode}: ${response.body}");
      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ API Error: $e");
      debugPrint("📍 Stack trace: $stackTrace");
      return http.Response('{"message": "$genericUnexpectedMessage"}', 500);
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

      final response = await _withRetry(
        () => http
            .delete(Uri.parse(url), headers: headers)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                debugPrint("⏱️ Request timeout after 30 seconds");
                return http.Response('{"error": "Request timeout"}', 408);
              },
            ),
      );

      debugPrint("📥 Response ${response.statusCode}: ${response.body}");
      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ API Error: $e");
      debugPrint("📍 Stack trace: $stackTrace");
      return http.Response('{"message": "$genericUnexpectedMessage"}', 500);
    }
  }

  static Future<http.Response> uploadFile(
    String path, {
    String fieldName = "file",
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    bool requiresAuth = true,
    Map<String, String>? fields,
  }) async {
    try {
      final token = requiresAuth ? await SecureStorage.readToken() : null;

      if (requiresAuth && token == null) {
        debugPrint("❌ No auth token found!");
        return http.Response('{"error": "No authentication token"}', 401);
      }

      if (filePath == null && fileBytes == null) {
        return http.Response('{"error": "No file provided"}', 400);
      }

      final url = "$_baseUrl$path";
      debugPrint("🌐 UPLOAD $url");

      final request = http.MultipartRequest("POST", Uri.parse(url));
      if (token != null) {
        request.headers["Authorization"] = "Bearer $token";
        debugPrint("🔑 Token: ${token.substring(0, 20)}...");
      } else {
        debugPrint("🔓 Public upload request (no token)");
      }

      if (fields != null && fields.isNotEmpty) {
        request.fields.addAll(fields);
      }

      if (fileBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            fieldName,
            fileBytes,
            filename: fileName ?? "upload.pdf",
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            filePath!,
            filename: fileName,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("📥 Upload response ${response.statusCode}: ${response.body}");
      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ Upload API Error: $e");
      debugPrint("📍 Stack trace: $stackTrace");
      return http.Response('{"message": "$genericUnexpectedMessage"}', 500);
    }
  }
}
