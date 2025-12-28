import 'package:flutter/material.dart';

import '../../guards/auth_guard.dart';
import '../../screens/auth/unauthorized_access_screen.dart';

/// Widget que muestra contenido solo si el usuario tiene el rol requerido
class RoleBasedWidget extends StatelessWidget {
  final Widget child;
  final String requiredRole;
  final Widget? fallbackWidget;

  const RoleBasedWidget({
    super.key,
    required this.child,
    required this.requiredRole,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.hasRole(context, requiredRole)) {
      return child;
    }

    return fallbackWidget ?? const SizedBox.shrink();
  }
}

/// Widget que muestra contenido solo si el usuario puede acceder a inventario
class InventoryAccessWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallbackWidget;

  const InventoryAccessWidget({
    super.key,
    required this.child,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.canAccessInventory(context)) {
      return child;
    }

    return fallbackWidget ??
        const UnauthorizedAccessScreen(
          featureName: 'Inventario',
          requiredRole: 'sudo, admin o almacenista',
        );
  }
}

/// Widget que muestra contenido solo si el usuario puede acceder a ventas
class SalesAccessWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallbackWidget;

  const SalesAccessWidget({
    super.key,
    required this.child,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.canAccessSales(context)) {
      return child;
    }

    return fallbackWidget ??
        const UnauthorizedAccessScreen(
          featureName: 'Ventas',
          requiredRole: 'sudo, admin o ventas',
        );
  }
}

/// Widget que muestra contenido solo si el usuario puede acceder a reportes
class ReportsAccessWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallbackWidget;

  const ReportsAccessWidget({
    super.key,
    required this.child,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.canAccessReports(context)) {
      return child;
    }

    return fallbackWidget ??
        const UnauthorizedAccessScreen(
          featureName: 'Reportes',
          requiredRole: 'sudo o admin',
        );
  }
}

/// Widget que muestra contenido solo si el usuario puede acceder a auditoría
class AuditAccessWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallbackWidget;

  const AuditAccessWidget({
    super.key,
    required this.child,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.canAccessAudit(context)) {
      return child;
    }

    return fallbackWidget ??
        const UnauthorizedAccessScreen(
          featureName: 'Auditoría',
          requiredRole: 'sudo',
        );
  }
}

/// Widget que muestra contenido solo si el usuario puede gestionar usuarios
class UserManagementAccessWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallbackWidget;

  const UserManagementAccessWidget({
    super.key,
    required this.child,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.canManageUsers(context)) {
      return child;
    }

    return fallbackWidget ??
        const UnauthorizedAccessScreen(
          featureName: 'Gestión de Usuarios',
          requiredRole: 'sudo o admin',
        );
  }
}

/// Widget que muestra contenido solo si el usuario puede modificar stock
class StockModificationAccessWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallbackWidget;

  const StockModificationAccessWidget({
    super.key,
    required this.child,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.canModifyStock(context)) {
      return child;
    }

    return fallbackWidget ??
        const UnauthorizedAccessScreen(
          featureName: 'Modificación de Stock',
          requiredRole: 'sudo, admin o almacenista',
        );
  }
}

/// Widget que muestra contenido solo si el usuario puede crear ventas
class SalesCreationAccessWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallbackWidget;

  const SalesCreationAccessWidget({
    super.key,
    required this.child,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.canCreateSales(context)) {
      return child;
    }

    return fallbackWidget ??
        const UnauthorizedAccessScreen(
          featureName: 'Creación de Ventas',
          requiredRole: 'sudo, admin o ventas',
        );
  }
}

/// Widget que muestra un botón solo si el usuario tiene el permiso requerido
class PermissionButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String requiredRole;
  final String? tooltip;

  const PermissionButton({
    super.key,
    required this.child,
    this.onPressed,
    required this.requiredRole,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.hasRole(context, requiredRole)) {
      return Tooltip(
        message: tooltip ?? '',
        child: child,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Widget que muestra un botón solo si el usuario puede acceder a inventario
class InventoryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;

  const InventoryButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.canAccessInventory(context)) {
      return Tooltip(
        message: tooltip ?? '',
        child: child,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Widget que muestra un botón solo si el usuario puede acceder a ventas
class SalesButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;

  const SalesButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.canAccessSales(context)) {
      return Tooltip(
        message: tooltip ?? '',
        child: child,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Widget que muestra un botón solo si el usuario puede acceder a reportes
class ReportsButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;

  const ReportsButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.canAccessReports(context)) {
      return Tooltip(
        message: tooltip ?? '',
        child: child,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Widget que muestra un botón solo si el usuario puede acceder a auditoría
class AuditButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;

  const AuditButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.canAccessAudit(context)) {
      return Tooltip(
        message: tooltip ?? '',
        child: child,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Widget que muestra un botón solo si el usuario puede gestionar usuarios
class UserManagementButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;

  const UserManagementButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.canManageUsers(context)) {
      return Tooltip(
        message: tooltip ?? '',
        child: child,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Widget que muestra un botón solo si el usuario puede modificar stock
class StockModificationButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;

  const StockModificationButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.canModifyStock(context)) {
      return Tooltip(
        message: tooltip ?? '',
        child: child,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Widget que muestra un botón solo si el usuario puede crear ventas
class SalesCreationButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;

  const SalesCreationButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthGuard.canCreateSales(context)) {
      return Tooltip(
        message: tooltip ?? '',
        child: child,
      );
    }

    return const SizedBox.shrink();
  }
}
