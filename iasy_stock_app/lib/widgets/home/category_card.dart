import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';

class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final String route;
  final bool isSelected;

  const CategoryCard({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    required this.route,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final iconColor = theme.iconTheme.color ?? textColor;

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
          onTap: () => context.push(route),
          hoverColor: AppColors.primary(context).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Icono más grande con relleno más notorio
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary(context).withOpacity(0.28)
                            : color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary(context).withOpacity(0.4)
                              : color.withOpacity(0.28),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? AppColors.primary(context) : color,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Título más alineado a la parte inferior
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary(context) : textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
