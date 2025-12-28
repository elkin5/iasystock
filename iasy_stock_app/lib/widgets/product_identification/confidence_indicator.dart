import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Widget que muestra el nivel de confianza de una identificación de producto
///
/// Muestra una barra de progreso con código de colores según el nivel:
/// - Verde (95-100%): Muy alta confianza
/// - Azul (85-94%): Alta confianza
/// - Naranja (70-84%): Media confianza
/// - Rojo (0-69%): Baja confianza
class ConfidenceIndicator extends StatelessWidget {
  /// Nivel de confianza (0-100)
  final double confidence;

  /// Si se debe mostrar el porcentaje como texto
  final bool showPercentage;

  /// Altura de la barra de progreso
  final double height;

  /// Si se debe mostrar la etiqueta descriptiva
  final bool showLabel;

  const ConfidenceIndicator({
    super.key,
    required this.confidence,
    this.showPercentage = true,
    this.height = 8.0,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height / 2),
                child: LinearProgressIndicator(
                  value: confidence / 100,
                  backgroundColor: AppColors.surfaceBorder(context),
                  color: _getColor(context),
                  minHeight: height,
                ),
              ),
            ),
            if (showPercentage) ...[
              const SizedBox(width: 12),
              Text(
                '${confidence.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getColor(context),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            _getLabel(),
            style: TextStyle(
              fontSize: 12,
              color: _getColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  /// Retorna el color según el nivel de confianza
  Color _getColor(BuildContext context) {
    if (confidence >= 95) return AppColors.success(context);
    if (confidence >= 85) return AppColors.info(context);
    if (confidence >= 70) return AppColors.warning(context);
    return AppColors.danger(context);
  }

  /// Retorna la etiqueta descriptiva según el nivel de confianza
  String _getLabel() {
    if (confidence >= 95) return 'Muy Alta';
    if (confidence >= 85) return 'Alta';
    if (confidence >= 70) return 'Media';
    return 'Baja';
  }
}

/// Widget que muestra el nivel de confianza con ícono y descripción completa
class ConfidenceIndicatorDetailed extends StatelessWidget {
  final double confidence;

  const ConfidenceIndicatorDetailed({
    super.key,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: _getColor(context).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _getColor(context).withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIcon(),
                  color: _getColor(context),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nivel de Confianza',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted(context),
                  ),
                ),
                const Spacer(),
                Text(
                  '${confidence.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConfidenceIndicator(
              confidence: confidence,
              showPercentage: false,
              height: 6,
            ),
            const SizedBox(height: 4),
            Text(
              _getDescription(),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(BuildContext context) {
    if (confidence >= 95) return AppColors.success(context);
    if (confidence >= 85) return AppColors.info(context);
    if (confidence >= 70) return AppColors.warning(context);
    return AppColors.danger(context);
  }

  IconData _getIcon() {
    if (confidence >= 95) return Icons.check_circle;
    if (confidence >= 85) return Icons.check_circle_outline;
    if (confidence >= 70) return Icons.warning_amber;
    return Icons.error_outline;
  }

  String _getDescription() {
    if (confidence >= 95) {
      return 'Identificación muy confiable. Raramente está incorrecta.';
    }
    if (confidence >= 85) {
      return 'Identificación confiable. Generalmente es correcta.';
    }
    if (confidence >= 70) {
      return 'Identificación probable. Revisa antes de confirmar.';
    }
    return 'Baja confianza. Verifica cuidadosamente el resultado.';
  }
}
