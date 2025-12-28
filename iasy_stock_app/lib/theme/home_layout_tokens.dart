import 'package:flutter/material.dart';

import 'app_colors.dart';

class HomeLayoutTokens {
  static const double sectionPadding = 16;
  static const double sectionSpacing = 24;
  static const double cardRadius = 12;
  static const double smallSpacing = 12;

  static BorderRadiusGeometry borderRadius([double? radius]) =>
      BorderRadius.circular(radius ?? cardRadius);

  static List<BoxShadow> sectionShadow(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.shadowColor;
    return [
      BoxShadow(
        color: baseColor.withOpacity(0.08),
        blurRadius: 8,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static Color defaultBorderColor(BuildContext context) =>
      AppColors.surfaceBorder(context);
}
