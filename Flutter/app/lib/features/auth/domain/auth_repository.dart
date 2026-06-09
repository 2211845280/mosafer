import '../../../shared/models/result.dart';

abstract class AuthRepository {
  Future<Result<void>> login({required String email, required String password});

  Future<Result<void>> register({
    required String email,
    required String password,
    required String fullName,
  });

  Future<Result<String?>> requestPasswordReset({required String email});

  Future<Result<void>> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<Result<void>> logout();

  Future<Result<bool>> isAuthenticated();

  Future<Result<void>> refreshSession();
}
