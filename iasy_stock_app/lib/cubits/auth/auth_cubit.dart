import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../models/auth/auth_user_model.dart';
import '../../services/auth/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final Logger _logger = Logger();

  AuthCubit(this._authService) : super(const AuthStateInitial()) {
    _checkAuthStatus();
  }

  /// Verifica el estado de autenticación al inicializar
  Future<void> _checkAuthStatus() async {
    try {
      emit(const AuthStateLoading());

      final user = await _authService.getCurrentUser();
      if (user != null) {
        emit(AuthStateAuthenticated(user));
        _logger.i('Usuario autenticado encontrado: ${user.username}');
      } else {
        emit(const AuthStateUnauthenticated());
        _logger.i('No hay usuario autenticado');
      }
    } catch (e, stackTrace) {
      _logger.e('Error al verificar estado de autenticación',
          error: e, stackTrace: stackTrace);
      emit(AuthStateError('Error al verificar autenticación: $e'));
    }
  }

  /// Inicia sesión con OIDC
  Future<void> signIn(BuildContext context,
      {String? username, String? password}) async {
    try {
      emit(const AuthStateLoading());
      _logger.i('Iniciando proceso de autenticación OIDC');

      final user = await _authService.signIn(context);
      if (user != null) {
        // Verificar si el usuario existe en el backend
        bool userExists = false;
        try {
          userExists = await _authService.checkUserExists(user.id);
        } catch (e) {
          // Si hay error al verificar el usuario, continuar con la autenticación
          _logger.w(
              '⚠️ Error al verificar usuario en backend, continuando con autenticación: $e');
          userExists = true; // Asumir que el usuario existe para continuar
        }

        if (userExists) {
          emit(AuthStateAuthenticated(user));
          _logger.i('✅ Autenticación exitosa: ${user.username}');
          _logger
              .i('🔄 Estado actualizado - el usuario será redirigido a /home');
        } else {
          emit(AuthStateError('Usuario no autorizado en el sistema'));
          _logger.w('❌ Usuario no autorizado en el backend');
        }
      } else {
        emit(const AuthStateUnauthenticated());
        _logger.w('❌ Autenticación cancelada o fallida');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en autenticación', error: e, stackTrace: stackTrace);
      emit(AuthStateError('Error al iniciar sesión: $e'));
    }
  }

  /// Cierra sesión
  Future<void> signOut() async {
    try {
      emit(const AuthStateLoading());
      _logger.i('Cerrando sesión');

      await _authService.signOut();
      emit(const AuthStateUnauthenticated());
      _logger.i('Sesión cerrada exitosamente');
    } catch (e, stackTrace) {
      _logger.e('Error al cerrar sesión', error: e, stackTrace: stackTrace);
      emit(AuthStateError('Error al cerrar sesión: $e'));
    }
  }

  /// Renueva el token de acceso
  Future<void> refreshToken() async {
    try {
      final currentState = state;
      if (currentState is! AuthStateAuthenticated) {
        return;
      }

      _logger.i('Renovando token de acceso');

      // Obtener el usuario actual para verificar si necesita renovación
      final currentUser = currentState.user;

      // Verificar si el token realmente necesita renovación
      final now = DateTime.now();
      final timeUntilExpiry = currentUser.tokenExpiry.difference(now);

      // Si el token aún tiene más de 10 minutos de vida, no renovar
      if (timeUntilExpiry.inMinutes > 10) {
        _logger.d(
            'Token aún válido por ${timeUntilExpiry.inMinutes} minutos, no necesita renovación');
        return;
      }

      // Intentar renovar el token
      final user = await _authService.getCurrentUser();
      if (user != null) {
        emit(AuthStateAuthenticated(user));
        _logger.i('Token renovado exitosamente');
      } else {
        emit(const AuthStateUnauthenticated());
        _logger.w('No se pudo renovar el token');
      }
    } catch (e, stackTrace) {
      _logger.e('Error al renovar token', error: e, stackTrace: stackTrace);
      emit(AuthStateError('Error al renovar token: $e'));
    }
  }

  /// Limpia el estado de error
  void clearError() {
    if (state is AuthStateError) {
      emit(const AuthStateUnauthenticated());
    }
  }

  /// Obtiene el usuario actual si está autenticado
  AuthUser? get currentUser {
    final currentState = state;
    if (currentState is AuthStateAuthenticated) {
      return currentState.user;
    }
    return null;
  }

  /// Verifica si el usuario está autenticado
  bool get isAuthenticated => state is AuthStateAuthenticated;

  /// Verifica si el usuario tiene un rol específico
  bool hasRole(String role) {
    final user = currentUser;
    return user?.roles.contains(role) ?? false;
  }

  /// Verifica si el usuario es administrador
  bool get isAdmin => hasRole('admin');

  /// Verifica si el usuario es manager
  bool get isManager => hasRole('manager') || isAdmin;

  /// Obtiene el token de acceso actual
  String? get accessToken => currentUser?.accessToken;

  /// Verifica si el token está próximo a expirar (en los próximos 5 minutos)
  bool get isTokenExpiringSoon {
    final user = currentUser;
    if (user == null) return false;

    final now = DateTime.now();
    final expiry = user.tokenExpiry;
    final timeUntilExpiry = expiry.difference(now);

    return timeUntilExpiry.inMinutes <= 5;
  }

  /// Registra un nuevo usuario (con OIDC, el registro se hace en Keycloak)
  Future<void> registerUser({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    required String role,
  }) async {
    try {
      emit(const AuthStateLoading());
      _logger.i('El registro de usuarios debe realizarse en Keycloak');

      // Con OIDC, el registro de usuarios se maneja en Keycloak
      // Mostrar mensaje informativo
      emit(AuthStateError(
          'El registro de nuevos usuarios debe realizarse a través del panel de administración de Keycloak'));
    } catch (e, stackTrace) {
      _logger.e('Error al registrar usuario', error: e, stackTrace: stackTrace);
      emit(AuthStateError('Error al registrar usuario: $e'));
    }
  }
}
