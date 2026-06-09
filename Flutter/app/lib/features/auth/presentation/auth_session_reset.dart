import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/presentation/notifications_controller.dart';
import '../../profile/presentation/profile_state.dart';
import '../../trips/presentation/my_trips/my_trips_controller.dart';
import '../data/auth_repository_impl.dart';
import 'auth_session_controller.dart';

void _invalidateUserScopedProviders(dynamic ref) {
  ref.invalidate(profileControllerProvider);
  ref.invalidate(myTripsControllerProvider);
  ref.invalidate(notificationsControllerProvider);
  ref.invalidate(deletedTripsProvider);
}

/// Drops cached user data so the next screen load uses the current JWT.
void invalidateUserScopedProviders(Ref ref) {
  _invalidateUserScopedProviders(ref);
}

/// Clears tokens (optional) and resets auth + in-memory user state.
Future<void> resetUserSession(
  WidgetRef ref, {
  bool clearTokens = true,
}) async {
  _invalidateUserScopedProviders(ref);
  await ref
      .read(authSessionControllerProvider.notifier)
      .clear(clearStorage: clearTokens);
}

/// Server logout, then local session and cached user data cleanup.
Future<void> logoutUser(WidgetRef ref) async {
  await ref.read(authRepositoryProvider).logout();
  _invalidateUserScopedProviders(ref);
  await ref
      .read(authSessionControllerProvider.notifier)
      .clear(clearStorage: false);
}
