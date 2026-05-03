import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_session_controller.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/auth_repository.dart';
import '../../../notifications/data/notifications_repository.dart';

final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
      return LoginController(
        authRepository: ref.watch(authRepositoryProvider),
        authSessionController: ref.read(authSessionControllerProvider.notifier),
        notificationsRepository: ref.watch(notificationsRepositoryProvider),
      );
    });

class LoginController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final AuthSessionController _authSessionController;
  final NotificationsRepository _notificationsRepository;

  LoginController({
    required AuthRepository authRepository,
    required AuthSessionController authSessionController,
    required NotificationsRepository notificationsRepository,
  }) : _authRepository = authRepository,
       _authSessionController = authSessionController,
       _notificationsRepository = notificationsRepository,
       super(const AsyncValue.data(null));

  Future<bool> login({required String email, required String password}) async {
    state = const AsyncValue.loading();

    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    return result.when(
      success: (_) {
        _authSessionController.setAuthenticated();
        unawaited(_notificationsRepository.registerCurrentDevice());
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
