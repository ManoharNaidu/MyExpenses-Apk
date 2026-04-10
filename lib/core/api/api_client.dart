import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

// ignore: always_declare_return_types
parseJson(String text) {
  return compute(_parseAndDecode, text);
}

class ApiClient {
  static final Dio _dio = _createDio();
  static String get _baseUrl {
    final envUrl = dotenv.get('API_URL', fallback: '');

    // // In debug mode, we default to localhost unless explicitly overridden.
    // if (kDebugMode && (envUrl.isEmpty || envUrl.contains('onrender.com'))) {
    //   String target = defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
    //   final localUrl = 'http://$target:8000/api/v1';
    //   debugPrint('DEBUG MODE: Overriding $envUrl to local backend: $localUrl');
    //   return localUrl;
    // }

    if (envUrl.isNotEmpty) return envUrl;
    return 'https://my-expenses-backend-fastapi.onrender.com/api/v1';
  }

  static String get baseUrl => _baseUrl;

  static const String genericUnexpectedMessage =
      'Something unexpected happened. Please try again.';

  static void setUnauthorizedCallback(UnauthorizedCallback cb) {
    _onUnauthorized = cb;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.plain,
      ),
    );

    dio.transformer = BackgroundTransformer()..jsonDecodeCallback = parseJson;

    dio.interceptors.add(
      InterceptorsWrapper(
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
          if (e.response?.statusCode == 401 &&
              !e.requestOptions.extra.containsKey('noAuth') &&
              !e.requestOptions.extra.containsKey('skipUnauthorizedHandler')) {
            await _handleUnauthorized();
          }
          return handler.next(e);
        },
      ),
    );

    return dio;
  }

  static Future<void> _handleUnauthorized() async {
    debugPrint('🔒 401 received');
    if (_onUnauthorized != null) await _onUnauthorized!();
  }

  static bool isSuccess(int statusCode) =>
      statusCode >= 200 && statusCode < 300;

  static String extractErrorMessage(
    LegacyHttpResponse response, {
    String fallbackMessage = genericUnexpectedMessage,
  }) {
    if (response.body.isEmpty) return fallbackMessage;

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return decoded['message']?.toString() ??
            decoded['detail']?.toString() ??
            decoded['error']?.toString() ??
            response.body;
      }
    } catch (_) {}

    return response.body;
  }

  static void ensureSuccess(
    LegacyHttpResponse response, {
    String fallbackMessage = genericUnexpectedMessage,
  }) {
    if (isSuccess(response.statusCode)) return;
    throw ApiException(
      extractErrorMessage(response, fallbackMessage: fallbackMessage),
      statusCode: response.statusCode,
    );
  }

  static LegacyHttpResponse _wrap(
    Response? response, {
    String? defaultMessage,
  }) {
    if (response == null) {
      final msg = defaultMessage ?? genericUnexpectedMessage;
      return LegacyHttpResponse(500, '{"message": "$msg"}');
    }

    final data = response.data;
    final body = data is String
        ? data
        : data == null
        ? ''
        : jsonEncode(data);
    return LegacyHttpResponse(response.statusCode ?? 500, body);
  }

  static String _dioErrorToMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet.';
      case DioExceptionType.connectionError:
        return 'No internet connection or server is unreachable.';
      default:
        return genericUnexpectedMessage;
    }
  }

  static Future<LegacyHttpResponse> post(
    String path,
    Object? body, {
    bool requiresAuth = true,
  }) async {
    try {
      final res = await _dio.post(
        path,
        data: body,
        options: Options(extra: requiresAuth ? {} : {'noAuth': true}),
      );
      return _wrap(res);
    } on DioException catch (e) {
      if (e.response != null) return _wrap(e.response);
      return _wrap(null, defaultMessage: _dioErrorToMessage(e));
    }
  }

  static Future<LegacyHttpResponse> get(
    String path, {
    bool suppressUnauthorizedHandler = false,
    bool requiresAuth = true,
  }) async {
    try {
      final res = await _dio.get(
        path,
        options: Options(
          extra: {
            if (!requiresAuth) 'noAuth': true,
            if (suppressUnauthorizedHandler) 'skipUnauthorizedHandler': true,
          },
        ),
      );
      return _wrap(res);
    } on DioException catch (e) {
      if (e.response != null) return _wrap(e.response);
      return _wrap(null, defaultMessage: _dioErrorToMessage(e));
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

  static Future<LegacyHttpResponse> delete(String path, {Object? data}) async {
    try {
      final res = await _dio.delete(path, data: data);
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
        fileTarget = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName ?? 'upload.pdf',
        );
      } else if (filePath != null) {
        fileTarget = await MultipartFile.fromFile(filePath, filename: fileName);
      } else {
        return LegacyHttpResponse(400, '{"error": "No file provided"}');
      }

      final formData = FormData.fromMap({...?fields, fieldName: fileTarget});

      final res = await _dio.post(
        path,
        data: formData,
        options: Options(extra: requiresAuth ? {} : {'noAuth': true}),
      );
      return _wrap(res);
    } on DioException catch (e) {
      return _wrap(e.response);
    }
  }
}
