import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';

/// Legacy compat response to avoid rewriting 20+ callers right now.
/// The callers expect `res.statusCode` and `res.body`.
class LegacyHttpResponse {
  final int statusCode;
  final String body;
  LegacyHttpResponse(this.statusCode, this.body);
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

typedef UnauthorizedCallback = Future<void> Function();
UnauthorizedCallback? _onUnauthorized;

_parseAndDecode(String response) {
  return jsonDecode(response);
}

parseJson(String text) {
  return compute(_parseAndDecode, text);
}

class ApiClient {
  static final Dio _dio = _createDio();
  static String get _baseUrl {
    const envUrl = String.fromEnvironment('API_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;
    return 'https://my-expenses-backend-fastapi.onrender.com/api/v1';
  }

  static const String genericUnexpectedMessage = 'Something unexpected happened. Please try again.';

  static void setUnauthorizedCallback(UnauthorizedCallback cb) {
    _onUnauthorized = cb;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.plain,
    ));

    dio.transformer = BackgroundTransformer()..jsonDecodeCallback = parseJson;

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!options.extra.containsKey('noAuth')) {
          final token = await SecureStorage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401 && !e.requestOptions.extra.containsKey('noAuth')) {
          await _handleUnauthorized();
        }
        return handler.next(e);
      },
    ));

    return dio;
  }

  static Future<void> _handleUnauthorized() async {
    debugPrint('🔒 401 received — clearing session');
    await SecureStorage.clear();
    if (_onUnauthorized != null) await _onUnauthorized!();
  }

  static bool isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  static String extractErrorMessage(LegacyHttpResponse response, {String fallbackMessage = genericUnexpectedMessage}) {
    if (response.body.isEmpty) return fallbackMessage;
    
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
         return decoded['message']?.toString() ?? decoded['detail']?.toString() ?? decoded['error']?.toString() ?? response.body;
      }
    } catch (_) { }
    
    return response.body; 
  }

  static void ensureSuccess(LegacyHttpResponse response, {String fallbackMessage = genericUnexpectedMessage}) {
    if (isSuccess(response.statusCode)) return;
    throw ApiException(extractErrorMessage(response, fallbackMessage: fallbackMessage), statusCode: response.statusCode);
  }

  static LegacyHttpResponse _wrap(Response? response) {
    if (response == null) return LegacyHttpResponse(500, '{"message": "$genericUnexpectedMessage"}');
    return LegacyHttpResponse(response.statusCode ?? 500, response.data?.toString() ?? '');
  }

  static Future<LegacyHttpResponse> post(String path, Object? body, {bool requiresAuth = true}) async {
    try {
      final res = await _dio.post(path, data: body, options: Options(extra: requiresAuth ? {} : {'noAuth': true}));
      return _wrap(res);
    } on DioException catch (e) {
      return _wrap(e.response);
    }
  }

  static Future<LegacyHttpResponse> get(String path) async {
    try {
      final res = await _dio.get(path);
      return _wrap(res);
    } on DioException catch (e) {
      return _wrap(e.response);
    }
  }

  static Future<LegacyHttpResponse> put(String path, Map body) async {
    try {
      final res = await _dio.put(path, data: body);
      return _wrap(res);
    } on DioException catch (e) {
      return _wrap(e.response);
    }
  }

  static Future<LegacyHttpResponse> delete(String path) async {
    try {
      final res = await _dio.delete(path);
      return _wrap(res);
    } on DioException catch (e) {
      return _wrap(e.response);
    }
  }

  static Future<LegacyHttpResponse> uploadFile(
    String path, {
    String fieldName = 'file',
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    bool requiresAuth = true,
    Map<String, String>? fields,
  }) async {
    try {
      Object? fileTarget;
      if (fileBytes != null) {
        fileTarget = MultipartFile.fromBytes(fileBytes, filename: fileName ?? 'upload.pdf');
      } else if (filePath != null) {
        fileTarget = await MultipartFile.fromFile(filePath, filename: fileName);
      } else {
        return LegacyHttpResponse(400, '{"error": "No file provided"}');
      }

      final formData = FormData.fromMap({
        ...?fields,
        fieldName: fileTarget,
      });

      final res = await _dio.post(
        path, 
        data: formData, 
        options: Options(extra: requiresAuth ? {} : {'noAuth': true})
      );
      return _wrap(res);
    } on DioException catch (e) {
      return _wrap(e.response);
    }
  }
}