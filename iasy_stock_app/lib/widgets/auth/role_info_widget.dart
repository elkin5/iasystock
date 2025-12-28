import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../services/menu_service.dart';
import '../../theme/app_colors.dart';
import '../menu/menu_item.dart';

/// Widget que muestra información sobre los roles y permisos del usuario actual
class RoleInfoWidget extends StatelessWidget {
  final bool showDetailedInfo;
  final VoidCallback? onToggle;

  const RoleInfoWidget({
    super.key,
    this.showDetailedInfo = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthStateAuthenticated) {
          final user = state.user;
          final accessibleItems = MenuService.getMenuItemsForUser(user.roles);
          final allItems = MenuService.getAllMenuItems();

          return Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.surfaceBorder(context),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary(context).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.security_rounded,
                          color: AppColors.primary(context),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Información de Roles y Permisos',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      if (onToggle != null)
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceEmphasis(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(
                              showDetailedInfo
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                            onPressed: onToggle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Información básica
                  _buildBasicInfo(context, user, accessibleItems, allItems),

                  if (showDetailedInfo) ...[
                    const SizedBox(height: 20),
                    _buildDetailedInfo(context, user.roles),
                  ],
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBasicInfo(
    BuildContext context,
    dynamic user,
    List<MenuItem> accessibleItems,
    List<MenuItem> allItems,
  ) {
    final theme = Theme.of(context);
    final percentage = (accessibleItems.length / allItems.length * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usuario: ${user.firstName} ${user.lastName}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Roles: ${user.roles.join(', ')}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withOpacity(0.1),
                      theme.primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$percentage% acceso',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Puedes acceder a ${accessibleItems.length} de ${allItems.length} elementos del menú',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedInfo(BuildContext context, List<String> userRoles) {
    final theme = Theme.of(context);
    final groupedItems = MenuService.getMenuItemsGroupedByAccess(userRoles);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elementos disponibles por categoría:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...MenuAccessType.values.map((accessType) {
          if (!groupedItems.containsKey(accessType)) {
            return const SizedBox.shrink();
          }

          final items = groupedItems[accessType]!;
          final accessColor = MenuService.getAccessColor(accessType, context);
          final accessIcon = MenuService.getAccessIcon(accessType);
          final accessDescription =
              MenuService.getAccessDescription(accessType);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  accessIcon,
                  size: 16,
                  color: accessColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$accessDescription: ${items.length} elemento${items.length != 1 ? 's' : ''}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        _buildRolesLegend(context, userRoles),
      ],
    );
  }

  Widget _buildRolesLegend(BuildContext context, List<String> userRoles) {
    final theme = Theme.of(context);
    final allRoles = ['sudo', 'admin', 'almacenista', 'ventas'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leyenda de roles:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: allRoles.map((role) {
            final hasRole = userRoles.contains(role);
            final color = _getRoleColor(context, role);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasRole
                    ? color.withOpacity(0.2)
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasRole ? color : theme.dividerColor,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasRole ? Icons.check_circle : Icons.cancel,
                    size: 12,
                    color: hasRole
                        ? color
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    role,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hasRole
                          ? color
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: hasRole ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getRoleColor(BuildContext context, String role) {
    switch (role) {
      case 'sudo':
        return AppColors.danger(context);
      case 'admin':
        return AppColors.info(context);
      case 'almacenista':
        return AppColors.warning(context);
      case 'ventas':
        return AppColors.success(context);
      default:
        return Theme.of(context).primaryColor;
    }
  }
}

/// Widget compacto que muestra solo los roles del usuario
class CompactRoleInfoWidget extends StatelessWidget {
  const CompactRoleInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthStateAuthenticated) {
          final user = state.user;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    size: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  user.roles.join(', '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
