import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/menu_service.dart';
import '../../theme/app_colors.dart';
import 'menu_item.dart';

class MenuCard extends StatelessWidget {
  final MenuItem item;
  final bool isSelected;
  final bool showAccessInfo;
  final VoidCallback? onTap;

  const MenuCard({
    super.key,
    required this.item,
    required this.isSelected,
    this.showAccessInfo = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final iconColor = theme.iconTheme.color ?? textColor;
    final accessColor = MenuService.getAccessColor(item.accessType, context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary(context).withOpacity(0.1),
                  AppColors.primary(context).withOpacity(0.05),
                ],
              )
            : null,
        border: Border.all(
          color: isSelected
              ? AppColors.primary(context).withOpacity(0.3)
              : AppColors.surfaceBorder(context),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(isSelected ? 0.15 : 0.08),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => context.push(item.route),
          hoverColor: AppColors.primary(context).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: showAccessInfo ? 12 : 16,
              horizontal: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fila principal con icono, título y flecha
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary(context).withOpacity(0.2)
                            : AppColors.primary(context).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        color:
                            isSelected ? AppColors.primary(context) : iconColor,
                        size: showAccessInfo ? 18 : 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: showAccessInfo ? 15 : 17,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.primary(context)
                                  : textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.description != null && showAccessInfo)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                item.description!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textColor.withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (showAccessInfo)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accessColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: accessColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              MenuService.getAccessIcon(item.accessType),
                              size: 12,
                              color: accessColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              MenuService.getAccessDescription(item.accessType),
                              style: TextStyle(
                                fontSize: 9,
                                color: accessColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary(context).withOpacity(0.2)
                            : AppColors.surfaceEmphasis(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: isSelected
                            ? AppColors.primary(context)
                            : iconColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                // Roles disponibles (solo si hay espacio)
                if (showAccessInfo && item.getAccessibleRoles().isNotEmpty)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: item.getAccessibleRoles().take(3).map((role) {
                          final isCurrentRole =
                              _isCurrentUserRole(context, role);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCurrentRole
                                  ? accessColor.withOpacity(0.25)
                                  : AppColors.surfaceEmphasis(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrentRole
                                    ? accessColor.withOpacity(0.3)
                                    : AppColors.surfaceBorder(context),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              role,
                              style: TextStyle(
                                fontSize: 9,
                                color: isCurrentRole
                                    ? accessColor
                                    : textColor.withOpacity(0.7),
                                fontWeight: isCurrentRole
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isCurrentUserRole(BuildContext context, String role) {
    // Esta función necesitaría acceso al AuthCubit para verificar los roles del usuario actual
    // Por ahora retornamos false, pero se puede implementar si es necesario
    return false;
  }
}
