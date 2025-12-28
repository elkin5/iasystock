import '../../models/auth/auth_user_model.dart';

sealed class AuthState {
  const AuthState();
}

class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateAuthenticated extends AuthState {
  final AuthUser user;

  const AuthStateAuthenticated(this.user);
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateError extends AuthState {
  final String message;

  const AuthStateError(this.message);
}

class AuthStateNeedsRegistration extends AuthState {
  final AuthUser user;

  const AuthStateNeedsRegistration(this.user);
}
