import 'package:flutter/material.dart';

/// Enum para definir los tipos de acceso de los elementos del menú
enum MenuAccessType {
  general, // Acceso general (todos los usuarios autenticados)
  inventory, // sudo, admin, almacenista
  sales, // sudo, admin, ventas
  admin, // sudo, admin
  userManagement, // sudo, admin
  sudo, // solo sudo
  reports, // sudo, admin
  audit, // solo sudo
}

class MenuItem {
  final String title;
  final IconData icon;
  final String route;
  final MenuAccessType accessType;
  final String? description;
  final List<String>?
      requiredRoles; // Roles específicos si accessType es custom

  const MenuItem(
    this.title,
    this.icon,
    this.route,
    this.accessType, {
    this.description,
    this.requiredRoles,
  });

  /// Verifica si el usuario puede acceder a este elemento del menú
  bool canAccess(List<String> userRoles) {
    switch (accessType) {
      case MenuAccessType.general:
        return true;
      case MenuAccessType.inventory:
        return userRoles
            .any((role) => ['sudo', 'admin', 'almacenista'].contains(role));
      case MenuAccessType.sales:
        return userRoles
            .any((role) => ['sudo', 'admin', 'ventas'].contains(role));
      case MenuAccessType.admin:
        return userRoles.any((role) => ['sudo', 'admin'].contains(role));
      case MenuAccessType.userManagement:
        return userRoles.any((role) => ['sudo', 'admin'].contains(role));
      case MenuAccessType.sudo:
        return userRoles.contains('sudo');
      case MenuAccessType.reports:
        return userRoles.any((role) => ['sudo', 'admin'].contains(role));
      case MenuAccessType.audit:
        return userRoles.contains('sudo');
    }
  }

  /// Obtiene los roles que pueden acceder a este elemento
  List<String> getAccessibleRoles() {
    switch (accessType) {
      case MenuAccessType.general:
        return ['todos'];
      case MenuAccessType.inventory:
        return ['sudo', 'admin', 'almacenista'];
      case MenuAccessType.sales:
        return ['sudo', 'admin', 'ventas'];
      case MenuAccessType.admin:
        return ['sudo', 'admin'];
      case MenuAccessType.userManagement:
        return ['sudo', 'admin'];
      case MenuAccessType.sudo:
        return ['sudo'];
      case MenuAccessType.reports:
        return ['sudo', 'admin'];
      case MenuAccessType.audit:
        return ['sudo'];
    }
  }
}
