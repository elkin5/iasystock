import 'package:flutter/material.dart';

/// Paleta centralizada para unificar colores en toda la app.
class AppColors {
  static Color primary(BuildContext context) => Theme.of(context).primaryColor;
  static const Color onPrimary = Colors.white;

  static const Color surfaceBase = Colors.white;

  static Color surfaceEmphasis(BuildContext context) =>
      primary(context).withOpacity(0.05);

  static Color surfaceBorder(BuildContext context) =>
      Colors.grey.withOpacity(0.15);

  static Color textMuted(BuildContext context) => Colors.grey[600]!;

  static Color iconMuted(BuildContext context) => Colors.grey[500]!;

  static Color success(BuildContext context) => Colors.green[600]!;

  static Color warning(BuildContext context) => Colors.orange[600]!;

  static Color danger(BuildContext context) => Colors.red[600]!;

  static Color info(BuildContext context) => Colors.blue[600]!;

  static Color disabled(BuildContext context) =>
      Theme.of(context).disabledColor;
}
