import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Custom Dio interceptor for ClassMate.
///
/// SCOPE: This interceptor covers only NON-Firebase HTTP calls made
/// via Dio — specifically the FCM HTTP v1 API calls for push notifications.
///
/// ⚠️ IMPORTANT LIMITATION:
/// This interceptor has ZERO visibility into Firebase SDK traffic.
/// Firebase Auth, Firestore, Storage, FCM SDK, and Remote Config all
/// use the Firebase Android SDK's internal HTTP stack (Google-managed
/// OkHttp). A Dio interceptor cannot intercept these connections.
///
/// See SECURITY.md for full details on this limitation and mitigations.
class ClassMateDioInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[Dio] → ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[Dio] ← ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[Dio] ✗ ${err.type} ${err.requestOptions.uri}: ${err.message}');
    handler.next(err);
  }
}

/// Factory that creates a pre-configured Dio instance.
Dio createDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout:    const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept':        'application/json',
      },
    ),
  );
  dio.interceptors.add(ClassMateDioInterceptor());
  return dio;
}
