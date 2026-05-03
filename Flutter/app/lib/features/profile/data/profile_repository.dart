import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/result.dart';
import '../presentation/profile_state.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  Future<Result<ProfileState>> getProfile() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/users/me');
      return Success(ProfileState.fromJson(response.data ?? const {}));
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<ProfileState>> updateProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/users/me',
        data: {'full_name': fullName, 'email': email, 'phone': phoneNumber},
      );
      return Success(ProfileState.fromJson(response.data ?? const {}));
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/users/me/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      return const Success(null);
    } catch (e) {
      return Failure(_message(e));
    }
  }

  Future<Result<ProfileState>> uploadAvatar(String filePath) async {
    try {
      final response = await _apiClient.multipart<Map<String, dynamic>>(
        '/users/me/avatar',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath),
        }),
      );
      return Success(ProfileState.fromJson(response.data ?? const {}));
    } catch (e) {
      return Failure(_message(e));
    }
  }

  String _message(Object error) {
    return error.toString().replaceFirst('DioException [bad response]: ', '');
  }
}
