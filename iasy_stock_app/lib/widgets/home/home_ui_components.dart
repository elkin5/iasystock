import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/home_layout_tokens.dart';

class HomeSectionCard extends StatelessWidget {
  const HomeSectionCard({
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.addShadow = true,
    this.showBorder = true,
    this.border,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final bool addShadow;
  final bool showBorder;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = backgroundColor ?? AppColors.surfaceBase;
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(HomeLayoutTokens.sectionPadding),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: HomeLayoutTokens.borderRadius(),
        border: border ??
            (showBorder
                ? Border.all(
                    color: HomeLayoutTokens.defaultBorderColor(context),
                  )
                : null),
        boxShadow: addShadow ? HomeLayoutTokens.sectionShadow(context) : null,
      ),
      child: child,
    );
  }
}

class HomeActionButton extends StatelessWidget {
  const HomeActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
    this.fullWidth = true,
    this.padding,
    this.textStyle,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = onPressed != null ? color : color.withOpacity(0.45);
    final button = ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: textStyle ?? const TextStyle(fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveColor,
        foregroundColor: AppColors.onPrimary,
        padding:
            padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: HomeLayoutTokens.borderRadius(),
        ),
        elevation: onPressed != null ? 2 : 0,
        shadowColor: theme.primaryColor.withOpacity(0.2),
      ),
    );
    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class HomeOutlinedActionButton extends StatelessWidget {
  const HomeOutlinedActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
    this.fullWidth = true,
    this.padding,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = onPressed != null ? color : color.withOpacity(0.45);
    final button = OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: effectiveColor),
      label: Text(
        label,
        style: TextStyle(fontSize: 13, color: effectiveColor),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: effectiveColor),
        padding:
            padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: HomeLayoutTokens.borderRadius(),
        ),
      ),
    );
    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class HomeSummaryChip extends StatelessWidget {
  const HomeSummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.backgroundColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = backgroundColor ?? AppColors.surfaceEmphasis(context);
    final effectiveIconColor = iconColor ?? AppColors.iconMuted(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: HomeLayoutTokens.borderRadius(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: effectiveIconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color? iconColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: iconColor ?? theme.primaryColor.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted(context),
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}
