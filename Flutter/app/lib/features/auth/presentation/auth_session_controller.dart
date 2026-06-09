import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/secure_storage_service.dart';

class AuthSessionState {
  final bool isLoading;
  final bool isAuthenticated;

  const AuthSessionState({this.isLoading = true, this.isAuthenticated = false});

  AuthSessionState copyWith({bool? isLoading, bool? isAuthenticated}) {
    return AuthSessionState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final authSessionControllerProvider =
    StateNotifierProvider<AuthSessionController, AuthSessionState>((ref) {
      return AuthSessionController(
        ref.watch(secureStorageProvider),
        ref.watch(apiClientProvider),
      )..load();
    });

class AuthSessionController extends StateNotifier<AuthSessionState> {
  final SecureStorageService _secureStorage;
  final ApiClient _apiClient;

  AuthSessionController(this._secureStorage, this._apiClient)
    : super(const AuthSessionState());

  Future<void> load() async {
    final token = await _secureStorage.read(AppConstants.authTokenKey);
    if (token == null || token.isEmpty) {
      state = const AuthSessionState(
        isLoading: false,
        isAuthenticated: false,
      );
      return;
    }

    try {
      await _apiClient.get<Map<String, dynamic>>('/users/me');
      state = const AuthSessionState(isLoading: false, isAuthenticated: true);
    } catch (_) {
      await _secureStorage.deleteAll();
      state = const AuthSessionState(
        isLoading: false,
        isAuthenticated: false,
      );
    }
  }

  void setAuthenticated() {
    state = const AuthSessionState(isLoading: false, isAuthenticated: true);
  }

  Future<void> clear({bool clearStorage = true}) async {
    if (clearStorage) {
      await _secureStorage.deleteAll();
    }
    state = const AuthSessionState(isLoading: false, isAuthenticated: false);
  }
}
