import 'package:dio/dio.dart';

import 'env.dart';
import 'secure_store.dart';

/// Lỗi API có message đọc được từ FastAPI `detail`.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

Dio createDio(SecureStore store) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl(),
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: <String, dynamic>{
        Headers.acceptHeader: 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await store.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) {
        final msg = _parseDetail(err.response?.data);
        if (msg != null) {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              response: err.response,
              type: err.type,
              error: ApiException(msg, statusCode: err.response?.statusCode),
            ),
          );
          return;
        }
        handler.next(err);
      },
    ),
  );

  return dio;
}

String? _parseDetail(dynamic data) {
  if (data == null) return null;
  if (data is Map<String, dynamic>) {
    final d = data['detail'];
    if (d is String) return d;
    if (d is List) {
      return d.map((e) => e.toString()).join('\n');
    }
  }
  return null;
}

/// Lấy message từ DioError / ApiException.
String dioErrorMessage(Object e) {
  if (e is DioException) {
    if (e.error is ApiException) {
      return (e.error! as ApiException).message;
    }
    final parsed = _parseDetail(e.response?.data);
    if (parsed != null) return parsed;
    if (e.message != null && e.message!.isNotEmpty) return e.message!;
  }
  return e.toString();
}
