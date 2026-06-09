import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_session_controller.dart';
import '../auth_session_reset.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/auth_repository.dart';
import '../../../notifications/data/notifications_repository.dart';
import '../../../notifications/presentation/notifications_controller.dart';

final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
      return LoginController(
        ref: ref,
        authRepository: ref.watch(authRepositoryProvider),
        authSessionController: ref.read(authSessionControllerProvider.notifier),
        notificationsRepository: ref.watch(notificationsRepositoryProvider),
        reloadNotifications: () =>
            ref.read(notificationsControllerProvider.notifier).load(),
      );
    });

class LoginController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final AuthRepository _authRepository;
  final AuthSessionController _authSessionController;
  final NotificationsRepository _notificationsRepository;
  final Future<void> Function() _reloadNotifications;

  LoginController({
    required Ref ref,
    required AuthRepository authRepository,
    required AuthSessionController authSessionController,
    required NotificationsRepository notificationsRepository,
    required Future<void> Function() reloadNotifications,
  }) : _ref = ref,
       _authRepository = authRepository,
       _authSessionController = authSessionController,
       _notificationsRepository = notificationsRepository,
       _reloadNotifications = reloadNotifications,
       super(const AsyncValue.data(null));

  Future<bool> login({required String email, required String password}) async {
    state = const AsyncValue.loading();

    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    return result.when(
      success: (_) {
        invalidateUserScopedProviders(_ref);
        _authSessionController.setAuthenticated();
        unawaited(_notificationsRepository.registerCurrentDevice());
        unawaited(_reloadNotifications());
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
