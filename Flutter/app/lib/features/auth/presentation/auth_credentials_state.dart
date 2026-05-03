import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthCredentialsState {
  final String? savedPassword;

  const AuthCredentialsState({this.savedPassword});

  bool get hasSavedPassword =>
      savedPassword != null && savedPassword!.isNotEmpty;

  bool canLoginWith(String password) {
    if (!hasSavedPassword) {
      return true;
    }
    return password == savedPassword;
  }

  bool canChangeFrom(String currentPassword) {
    if (!hasSavedPassword) {
      return true;
    }
    return currentPassword == savedPassword;
  }
}

class AuthCredentialsController extends StateNotifier<AuthCredentialsState> {
  AuthCredentialsController() : super(const AuthCredentialsState());

  void updatePassword(String password) {
    state = AuthCredentialsState(savedPassword: password);
  }
}

final authCredentialsControllerProvider =
    StateNotifierProvider<AuthCredentialsController, AuthCredentialsState>(
      (ref) => AuthCredentialsController(),
    );
