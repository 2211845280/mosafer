import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';

class ProfileState {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String location;
  final String? avatarPath;

  const ProfileState({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.location,
    this.avatarPath,
  });

  factory ProfileState.fromJson(Map<String, dynamic> json) {
    final passenger = json['passenger'] as Map<String, dynamic>?;
    return ProfileState(
      fullName:
          passenger?['full_name'] as String? ??
          json['name'] as String? ??
          'Traveler',
      email: json['email'] as String? ?? '',
      phoneNumber: passenger?['phone'] as String? ?? '',
      location: 'Add your home location',
      avatarPath: json['avatar_path'] as String?,
    );
  }

  ProfileState copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? location,
    String? avatarPath,
  }) {
    return ProfileState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}

class ProfileController extends StateNotifier<AsyncValue<ProfileState>> {
  final ProfileRepository _repository;

  ProfileController(this._repository) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    final result = await _repository.getProfile();
    state = result.when(
      success: AsyncValue.data,
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );
  }

  Future<bool> updateProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateProfile(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
    );
    return result.when(
      success: (profile) {
        state = AsyncValue.data(profile);
        return true;
      },
      failure: (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> uploadAvatar(String filePath) async {
    final result = await _repository.uploadAvatar(filePath);
    return result.when(
      success: (profile) {
        state = AsyncValue.data(profile);
        return true;
      },
      failure: (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    return result.when(
      success: (_) => true,
      failure: (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return false;
      },
    );
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<ProfileState>>(
      (ref) => ProfileController(ref.watch(profileRepositoryProvider)),
    );
