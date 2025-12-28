import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';

class LogoutCallbackScreen extends StatefulWidget {
  const LogoutCallbackScreen({super.key});

  @override
  State<LogoutCallbackScreen> createState() => _LogoutCallbackScreenState();
}

class _LogoutCallbackScreenState extends State<LogoutCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _handleLogoutCallback();
  }

  void _handleLogoutCallback() async {
    try {
      // Emitir estado de no autenticado
      if (mounted) {
        context.read<AuthCubit>().emit(AuthStateUnauthenticated());
      }

      // Redirigir a la página de login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
    } catch (e) {
      // En caso de error, aún redirigir a login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Título
                Text(
                  'Iasy Stock',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),

                const SizedBox(height: 48),

                // Indicador de carga
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),

                const SizedBox(height: 24),

                // Mensaje
                Text(
                  'Cerrando sesión...',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
