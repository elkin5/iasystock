import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';

class AuthGuard {
  /// Verifica si el usuario está autenticado
  static bool isAuthenticated(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    return authCubit.isAuthenticated;
  }

  /// Verifica si el usuario tiene un rol específico
  static bool hasRole(BuildContext context, String role) {
    final authCubit = context.read<AuthCubit>();
    return authCubit.hasRole(role);
  }

  /// Verifica si el usuario es super usuario (sudo)
  static bool isSudo(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    return authCubit.hasRole('sudo');
  }

  /// Verifica si el usuario es administrador
  static bool isAdmin(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    return authCubit.hasRole('admin');
  }

  /// Verifica si el usuario es almacenista
  static bool isAlmacenista(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    return authCubit.hasRole('almacenista');
  }

  /// Verifica si el usuario es vendedor
  static bool isVentas(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    return authCubit.hasRole('ventas');
  }

  /// Verifica si el usuario puede acceder a inventario
  static bool canAccessInventory(BuildContext context) {
    return isSudo(context) || isAdmin(context) || isAlmacenista(context);
  }

  /// Verifica si el usuario puede acceder a ventas
  static bool canAccessSales(BuildContext context) {
    return isSudo(context) || isAdmin(context) || isVentas(context);
  }

  /// Verifica si el usuario puede acceder a reportes
  static bool canAccessReports(BuildContext context) {
    return isSudo(context) || isAdmin(context);
  }

  /// Verifica si el usuario puede acceder a auditoría
  static bool canAccessAudit(BuildContext context) {
    return isSudo(context);
  }

  /// Verifica si el usuario puede gestionar usuarios
  static bool canManageUsers(BuildContext context) {
    return isSudo(context) || isAdmin(context);
  }

  /// Verifica si el usuario puede modificar stock
  static bool canModifyStock(BuildContext context) {
    return isSudo(context) || isAdmin(context) || isAlmacenista(context);
  }

  /// Verifica si el usuario puede crear ventas
  static bool canCreateSales(BuildContext context) {
    return isSudo(context) || isAdmin(context) || isVentas(context);
  }

  /// Middleware para rutas protegidas
  static String? redirectIfNotAuthenticated(
      BuildContext context, GoRouterState state) {
    final authCubit = context.read<AuthCubit>();

    if (!authCubit.isAuthenticated) {
      return '/login';
    }

    return null;
  }

  /// Middleware para rutas que requieren rol específico
  static String? redirectIfNotAuthorized(
      BuildContext context, GoRouterState state, String requiredRole) {
    final authCubit = context.read<AuthCubit>();

    if (!authCubit.isAuthenticated) {
      return '/login';
    }

    if (!authCubit.hasRole(requiredRole)) {
      return '/unauthorized';
    }

    return null;
  }

  /// Middleware para rutas de super usuario
  static String? redirectIfNotSudo(BuildContext context, GoRouterState state) {
    return redirectIfNotAuthorized(context, state, 'sudo');
  }

  /// Middleware para rutas de administrador
  static String? redirectIfNotAdmin(BuildContext context, GoRouterState state) {
    return redirectIfNotAuthorized(context, state, 'admin');
  }

  /// Middleware para rutas de almacenista
  static String? redirectIfNotAlmacenista(
      BuildContext context, GoRouterState state) {
    return redirectIfNotAuthorized(context, state, 'almacenista');
  }

  /// Middleware para rutas de ventas
  static String? redirectIfNotVentas(
      BuildContext context, GoRouterState state) {
    return redirectIfNotAuthorized(context, state, 'ventas');
  }

  /// Middleware para rutas que requieren acceso a inventario
  static String? redirectIfCannotAccessInventory(
      BuildContext context, GoRouterState state) {
    final authCubit = context.read<AuthCubit>();

    if (!authCubit.isAuthenticated) {
      return '/login';
    }

    if (!canAccessInventory(context)) {
      return '/unauthorized';
    }

    return null;
  }

  /// Middleware para rutas que requieren acceso a ventas
  static String? redirectIfCannotAccessSales(
      BuildContext context, GoRouterState state) {
    final authCubit = context.read<AuthCubit>();

    if (!authCubit.isAuthenticated) {
      return '/login';
    }

    if (!canAccessSales(context)) {
      return '/unauthorized';
    }

    return null;
  }

  /// Middleware para rutas que requieren acceso a reportes
  static String? redirectIfCannotAccessReports(
      BuildContext context, GoRouterState state) {
    final authCubit = context.read<AuthCubit>();

    if (!authCubit.isAuthenticated) {
      return '/login';
    }

    if (!canAccessReports(context)) {
      return '/unauthorized';
    }

    return null;
  }

  /// Middleware para rutas que requieren acceso a auditoría
  static String? redirectIfCannotAccessAudit(
      BuildContext context, GoRouterState state) {
    final authCubit = context.read<AuthCubit>();

    if (!authCubit.isAuthenticated) {
      return '/login';
    }

    if (!canAccessAudit(context)) {
      return '/unauthorized';
    }

    return null;
  }
}

/// Widget wrapper para rutas protegidas
class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final String? requiredRole;
  final Widget? loadingWidget;
  final Widget? unauthorizedWidget;

  const ProtectedRoute({
    super.key,
    required this.child,
    this.requiredRole,
    this.loadingWidget,
    this.unauthorizedWidget,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        // Mostrar loading mientras se verifica la autenticación
        if (state is AuthStateLoading) {
          return loadingWidget ??
              const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
        }

        // Redirigir si no está autenticado
        if (state is AuthStateUnauthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Mostrar error si hay un problema
        if (state is AuthStateError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error de autenticación',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthCubit>().clearError();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        // Verificar rol si se requiere
        if (state is AuthStateAuthenticated && requiredRole != null) {
          if (!state.user.roles.contains(requiredRole)) {
            return unauthorizedWidget ??
                Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.block,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Acceso no autorizado',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No tienes permisos para acceder a esta sección.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.go('/home');
                          },
                          child: const Text('Volver al inicio'),
                        ),
                      ],
                    ),
                  ),
                );
          }
        }

        return child;
      },
    );
  }
}

/// Widget para mostrar información del usuario autenticado
class UserInfoWidget extends StatelessWidget {
  const UserInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthStateAuthenticated) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${state.user.firstName} ${state.user.lastName}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                state.user.email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
              if (state.user.roles.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: state.user.roles
                      .map((role) => Chip(
                            label: Text(role),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                            ),
                          ))
                      .toList(),
                ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
