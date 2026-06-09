import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import '../localization/accept_language_holder.dart';
import '../services/secure_storage_service.dart';
import '../../features/auth/presentation/auth_session_controller.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(secureStorage: ref.watch(secureStorageProvider));
});

class ApiClient {
  late final Dio _dio;
  final SecureStorageService secureStorage;

  ApiClient({required this.secureStorage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Accept-Language'] = AcceptLanguageHolder.value;
          final skipAuth = options.extra['skipAuth'] == true;
          final token = await secureStorage.readAccessToken();
          if (!skipAuth && token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              error.requestOptions.extra['skipRefresh'] != true) {
            final refreshed = await _refreshAccessToken();
            if (refreshed) {
              try {
                final requestOptions = error.requestOptions;
                requestOptions.headers['Authorization'] =
                    'Bearer ${await secureStorage.readAccessToken()}';
                final response = await _dio.fetch<dynamic>(requestOptions);
                return handler.resolve(response);
              } catch (_) {
                await secureStorage.deleteAll();
              }
            }
          }
          final exception = _handleError(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: exception,
              message: exception.message,
            ),
          );
        },
      ),
    );
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = await secureStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuth': true, 'skipRefresh': true}),
      );
      final data = response.data;
      final accessToken = data?['access_token'] as String?;
      final newRefreshToken = data?['refresh_token'] as String?;
      if (accessToken == null || newRefreshToken == null) {
        return false;
      }
      await secureStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );
      return true;
    } catch (_) {
      await secureStorage.deleteAll();
      return false;
    }
  }

  AppException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Connection timeout. Please try again.',
          code: 'TIMEOUT',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'No internet connection.',
          code: 'NO_CONNECTION',
        );
      default:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        final message = _extractErrorMessage(responseData) ??
            error.message ??
            'An error occurred';

        if (statusCode == 401) {
          return UnauthorizedException(message: message);
        }

        if (statusCode == 422) {
          return ValidationException(
            message: message,
            errors: responseData is Map<String, dynamic>
                ? responseData['errors']?.cast<String, List<String>>()
                : null,
          );
        }

        return AppException(message: message, statusCode: statusCode);
    }
  }

  /// Parses FastAPI error bodies where `detail` may be a string or a list of
  /// validation error objects.
  String? _extractErrorMessage(dynamic responseData) {
    if (responseData is! Map) return null;

    final message = responseData['message'];
    if (message is String && message.isNotEmpty) return message;

    final detail = responseData['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail is List) {
      final parts = <String>[];
      for (final item in detail) {
        if (item is Map) {
          final msg = item['msg'];
          if (msg is String && msg.isNotEmpty) {
            parts.add(msg);
          }
        } else if (item is String && item.isNotEmpty) {
          parts.add(item);
        }
      }
      if (parts.isNotEmpty) return parts.join('; ');
    }

    return null;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> multipart<T>(
    String path, {
    required FormData data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Uint8List?> getBytes(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<List<int>>(
      path,
      queryParameters: queryParameters,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      return null;
    }
    return Uint8List.fromList(data);
  }
}
