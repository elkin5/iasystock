import 'package:flutter/material.dart';

import '../config/get_it_config.dart';
import '../models/menu/user_model.dart';
import '../services/menu/user_service.dart';

/// Widget que muestra el usuario actual autenticado en un campo de solo lectura
/// Útil para formularios donde el usuario debe ser tomado automáticamente de la sesión
class CurrentUserField extends StatefulWidget {
  /// Texto de la etiqueta del campo
  final String labelText;

  /// Texto de ayuda adicional
  final String? helperText;

  /// Callback que se ejecuta cuando se obtiene el usuario actual
  final Function(UserModel)? onUserLoaded;

  /// Si debe mostrar un indicador de carga
  final bool showLoadingIndicator;

  const CurrentUserField({
    super.key,
    this.labelText = 'Usuario',
    this.helperText,
    this.onUserLoaded,
    this.showLoadingIndicator = true,
  });

  @override
  State<CurrentUserField> createState() => _CurrentUserFieldState();
}

class _CurrentUserFieldState extends State<CurrentUserField> {
  UserModel? _currentUser;
  bool _loadingCurrentUser = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userService = getIt<UserService>();
      final currentUser = await userService.getCurrentUser();

      if (mounted) {
        setState(() {
          _currentUser = currentUser;
          _loadingCurrentUser = false;
          _errorMessage = null;
        });

        // Ejecutar callback si está definido
        widget.onUserLoaded?.call(currentUser);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCurrentUser = false;
          _errorMessage = 'Error al cargar usuario actual: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCurrentUser && widget.showLoadingIndicator) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.labelText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      );
    }

    if (_currentUser == null) {
      return TextFormField(
        decoration: InputDecoration(
          labelText: widget.labelText,
          errorText: _errorMessage,
          helperText: widget.helperText,
        ),
        enabled: false,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      );
    }

    return TextFormField(
      decoration: InputDecoration(
        labelText: widget.labelText,
        helperText: widget.helperText ?? 'Usuario actual autenticado',
      ),
      controller: TextEditingController(
        text: _getDisplayText(_currentUser!),
      ),
      enabled: false,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }

  String _getDisplayText(UserModel user) {
    final name = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    if (name.isNotEmpty) {
      return '$name (${user.username})';
    }
    return user.username ?? 'Usuario';
  }

  /// Obtiene el usuario actual cargado
  UserModel? get currentUser => _currentUser;

  /// Indica si está cargando el usuario
  bool get isLoading => _loadingCurrentUser;

  /// Indica si hay un error
  bool get hasError => _errorMessage != null;
}
