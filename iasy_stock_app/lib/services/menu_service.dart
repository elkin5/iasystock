import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import '../widgets/menu/menu_item.dart';

/// Servicio que gestiona los elementos del menú y su filtrado por roles
class MenuService {
  static const List<MenuItem> _allMenuItems = [
    // Elementos básicos (acceso general)
    MenuItem(
      'Almacenes',
      Icons.warehouse,
      '/warehouses',
      MenuAccessType.general,
      description: 'Gestionar almacenes y ubicaciones',
    ),
    MenuItem(
      'Categorías',
      Icons.category,
      '/categories',
      MenuAccessType.general,
      description: 'Gestionar categorías de productos',
    ),
    MenuItem(
      'Productos',
      Icons.shopping_bag,
      '/products',
      MenuAccessType.inventory,
      description: 'Gestionar catálogo de productos',
    ),
    MenuItem(
      'Stock',
      Icons.inventory,
      '/stock/list',
      MenuAccessType.inventory,
      description: 'Control de inventario y existencias',
    ),
    MenuItem(
      'Ventas',
      Icons.sell,
      '/sales',
      MenuAccessType.sales,
      description: 'Gestionar ventas y transacciones',
    ),
    MenuItem(
      'Items de Venta',
      Icons.shopping_cart,
      '/sale_items',
      MenuAccessType.sales,
      description: 'Detalles de productos vendidos',
    ),
    MenuItem(
      'Personas',
      Icons.people,
      '/persons',
      MenuAccessType.general,
      description: 'Gestionar información de personas',
    ),

    MenuItem(
      'Promociones',
      Icons.local_offer,
      '/promotions',
      MenuAccessType.sales,
      description: 'Gestionar promociones y descuentos',
    ),
    MenuItem(
      'Usuarios',
      Icons.person,
      '/users',
      MenuAccessType.userManagement,
      description: 'Gestionar usuarios del sistema',
    ),

    MenuItem(
      'Logs de Auditoría',
      Icons.history,
      '/audit_logs',
      MenuAccessType.audit,
      description: 'Consultar logs de auditoría del sistema',
    ),
    MenuItem(
      'Configuraciones Generales',
      Icons.settings,
      '/general_settings',
      MenuAccessType.sudo,
      description: 'Configuraciones avanzadas del sistema',
    ),
  ];

  /// Obtiene todos los elementos del menú disponibles
  static List<MenuItem> getAllMenuItems() => List.unmodifiable(_allMenuItems);

  /// Obtiene los elementos del menú filtrados por los roles del usuario
  static List<MenuItem> getMenuItemsForUser(List<String> userRoles) {
    return _allMenuItems.where((item) => item.canAccess(userRoles)).toList();
  }

  /// Obtiene los elementos del menú agrupados por tipo de acceso
  static Map<MenuAccessType, List<MenuItem>> getMenuItemsGroupedByAccess(
      List<String> userRoles) {
    final accessibleItems = getMenuItemsForUser(userRoles);
    final Map<MenuAccessType, List<MenuItem>> grouped = {};

    for (final item in accessibleItems) {
      grouped.putIfAbsent(item.accessType, () => []).add(item);
    }

    return grouped;
  }

  /// Obtiene elementos del menú por tipo específico
  static List<MenuItem> getMenuItemsByAccessType(
      MenuAccessType accessType, List<String> userRoles) {
    return _allMenuItems
        .where((item) =>
            item.accessType == accessType && item.canAccess(userRoles))
        .toList();
  }

  /// Verifica si un usuario puede acceder a una ruta específica
  static bool canAccessRoute(String route, List<String> userRoles) {
    final menuItem = _allMenuItems.firstWhere(
      (item) => item.route == route,
      orElse: () => throw ArgumentError('Ruta no encontrada: $route'),
    );
    return menuItem.canAccess(userRoles);
  }

  /// Obtiene información sobre los permisos de un elemento del menú
  static String getAccessDescription(MenuAccessType accessType) {
    switch (accessType) {
      case MenuAccessType.general:
        return 'Acceso general';
      case MenuAccessType.inventory:
        return 'Acceso a inventario';
      case MenuAccessType.sales:
        return 'Acceso a ventas';
      case MenuAccessType.admin:
        return 'Acceso administrativo';
      case MenuAccessType.userManagement:
        return 'Gestión de usuarios';
      case MenuAccessType.sudo:
        return 'Super usuario';
      case MenuAccessType.reports:
        return 'Acceso a reportes';
      case MenuAccessType.audit:
        return 'Acceso a auditoría';
    }
  }

  /// Obtiene el icono asociado al tipo de acceso
  static IconData getAccessIcon(MenuAccessType accessType) {
    switch (accessType) {
      case MenuAccessType.general:
        return Icons.public;
      case MenuAccessType.inventory:
        return Icons.inventory_2;
      case MenuAccessType.sales:
        return Icons.point_of_sale;
      case MenuAccessType.admin:
        return Icons.admin_panel_settings;
      case MenuAccessType.userManagement:
        return Icons.people_alt;
      case MenuAccessType.sudo:
        return Icons.security;
      case MenuAccessType.reports:
        return Icons.assessment;
      case MenuAccessType.audit:
        return Icons.verified_user;
    }
  }

  /// Obtiene el color asociado al tipo de acceso
  static Color getAccessColor(MenuAccessType accessType, BuildContext context) {
    final theme = Theme.of(context);
    switch (accessType) {
      case MenuAccessType.general:
        return theme.colorScheme.primary;
      case MenuAccessType.inventory:
        return Colors.orange;
      case MenuAccessType.sales:
        return Colors.green;
      case MenuAccessType.admin:
        return Colors.blue;
      case MenuAccessType.userManagement:
        return Colors.purple;
      case MenuAccessType.sudo:
        return Colors.red;
      case MenuAccessType.reports:
        return Colors.indigo;
      case MenuAccessType.audit:
        return Colors.brown;
    }
  }
}

/// Widget que proporciona acceso al servicio de menú a través del contexto
class MenuServiceProvider extends StatelessWidget {
  final Widget child;

  const MenuServiceProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }

  /// Obtiene los elementos del menú para el usuario actual
  static List<MenuItem> getMenuItemsForCurrentUser(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    if (authCubit.state is AuthStateAuthenticated) {
      final user = (authCubit.state as AuthStateAuthenticated).user;
      return MenuService.getMenuItemsForUser(user.roles);
    }
    return [];
  }

  /// Obtiene los elementos del menú agrupados por tipo de acceso para el usuario actual
  static Map<MenuAccessType, List<MenuItem>> getMenuItemsGroupedForCurrentUser(
      BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    if (authCubit.state is AuthStateAuthenticated) {
      final user = (authCubit.state as AuthStateAuthenticated).user;
      return MenuService.getMenuItemsGroupedByAccess(user.roles);
    }
    return {};
  }
}
