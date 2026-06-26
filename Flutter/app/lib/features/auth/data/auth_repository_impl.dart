import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../shared/models/result.dart';
import '../domain/auth_repository.dart';
import '../presentation/auth_session_controller.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService secureStorage;

  AuthRepositoryImpl({required this.apiClient, required this.secureStorage});

  @override
  Future<Result<void>> login({
    required String email,
    required String password,
  }) async {
    try {
      await secureStorage.deleteAll();
      final response = await apiClient.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(extra: {'skipAuth': true}),
      );
      await _storeTokens(response.data);
      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(_errorMessage(e));
    }
  }

  @override
  Future<Result<void>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await apiClient.post<Map<String, dynamic>>(
        '/auth/register',
        data: {'name': fullName, 'email': email, 'password': password},
        options: Options(extra: {'skipAuth': true}),
      );
      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(_errorMessage(e));
    }
  }

  @override
  Future<Result<String?>> requestPasswordReset({required String email}) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email},
        options: Options(extra: {'skipAuth': true}),
      );
      final resetLink = response.data?['reset_link'] as String?;
      return Success<String?>(resetLink);
    } catch (e) {
      return Failure<String?>(_errorMessage(e));
    }
  }

  @override
  Future<Result<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await apiClient.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {'token': token, 'new_password': newPassword},
        options: Options(extra: {'skipAuth': true}),
      );
      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(_errorMessage(e));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await apiClient.post<Map<String, dynamic>>(
        '/auth/logout',
        options: Options(extra: {'skipRefresh': true}),
      );
      await secureStorage.deleteAll();
      return const Success<void>(null);
    } catch (e) {
      await secureStorage.deleteAll();
      return const Success<void>(null);
    }
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    try {
      final token = await secureStorage.readAccessToken();
      return Success<bool>(token != null && token.isNotEmpty);
    } catch (e) {
      return Failure<bool>(_errorMessage(e));
    }
  }

  @override
  Future<Result<void>> refreshSession() async {
    try {
      final refreshToken = await secureStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return const Failure<void>('No refresh token available.');
      }
      final response = await apiClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuth': true, 'skipRefresh': true}),
      );
      await _storeTokens(response.data);
      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(_errorMessage(e));
    }
  }

  Future<void> _storeTokens(Map<String, dynamic>? data) async {
    final accessToken = data?['access_token'] as String?;
    final refreshToken = data?['refresh_token'] as String?;
    if (accessToken == null || refreshToken == null) {
      throw StateError('Backend did not return auth tokens.');
    }
    await secureStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final handledError = error.error;
      if (handledError is AppException) {
        return handledError.message;
      }

      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'] ?? responseData['detail'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }

      return error.message ?? 'Unable to connect to the server.';
    }

    if (error is AppException) {
      return error.message;
    }

    return error.toString();
  }
}
