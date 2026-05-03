import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository_impl.dart';
import '../../domain/auth_repository.dart';
import '../auth_session_controller.dart';

final registerControllerProvider =
    StateNotifierProvider<RegisterController, AsyncValue<void>>((ref) {
      return RegisterController(
        authRepository: ref.watch(authRepositoryProvider),
        authSessionController: ref.read(authSessionControllerProvider.notifier),
      );
    });

class RegisterController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final AuthSessionController _authSessionController;

  RegisterController({
    required AuthRepository authRepository,
    required AuthSessionController authSessionController,
  }) : _authRepository = authRepository,
       _authSessionController = authSessionController,
       super(const AsyncValue.data(null));

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    final result = await _authRepository.register(
      fullName: fullName,
      email: email,
      password: password,
    );

    return result.when(
      success: (_) {
        _authSessionController.setAuthenticated();
        state = const AsyncValue.data(null);
        return true;
      },
      failure: (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return false;
      },
    );
  }
}
