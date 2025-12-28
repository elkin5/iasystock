import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/get_it_config.dart';
import '../../services/auth/auth_service.dart';

class CallbackScreen extends StatefulWidget {
  const CallbackScreen({super.key});

  @override
  State<CallbackScreen> createState() => _CallbackScreenState();
}

class _CallbackScreenState extends State<CallbackScreen> {
  bool _isProcessing = true;
  String _statusMessage = 'Procesando autenticación...';

  @override
  void initState() {
    super.initState();
    _processCallback();
  }

  Future<void> _processCallback() async {
    try {
      setState(() {
        _statusMessage = 'Verificando autenticación...';
      });

      final authService = getIt<AuthService>();

      // Procesar el callback de Keycloak
      final user = await authService.processWebCallback();

      if (user != null) {
        setState(() {
          _statusMessage = 'Autenticación exitosa!';
        });

        // Verificar si el usuario existe en el backend
        final userExists = await authService.checkUserExists(user.id);

        if (userExists) {
          // El AuthCubit ya maneja el estado de autenticación
          // Solo necesitamos redirigir a home
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            context.go('/home');
          }
        } else {
          setState(() {
            _isProcessing = false;
            _statusMessage = 'Usuario no autorizado en el sistema';
          });
        }
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Error en la autenticación. Intenta de nuevo.';
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error al procesar la autenticación: $e';
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
                if (_isProcessing) ...[
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                ],

                // Mensaje de estado
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),

                const SizedBox(height: 32),

                // Botón para reintentar si hay error
                if (!_isProcessing) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      context.go('/login');
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Volver al Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
