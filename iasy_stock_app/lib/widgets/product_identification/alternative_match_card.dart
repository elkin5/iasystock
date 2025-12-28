import 'package:flutter/material.dart';

import '../../models/product_identification/product_identification_models.dart';
import '../../theme/app_colors.dart';
import 'confidence_indicator.dart';

/// Widget que muestra una tarjeta de producto alternativo en la identificación
///
/// Usado en la pantalla de confirmación cuando hay múltiples coincidencias posibles
class AlternativeMatchCard extends StatelessWidget {
  /// Match alternativo a mostrar
  final IdentificationMatch match;

  /// Si esta alternativa está seleccionada
  final bool isSelected;

  /// Callback cuando se toca la tarjeta
  final VoidCallback onTap;

  const AlternativeMatchCard({
    super.key,
    required this.match,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? AppColors.info(context).withOpacity(0.1)
          : AppColors.surfaceBase,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? AppColors.info(context)
              : AppColors.surfaceBorder(context),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Imagen del producto
              _buildProductImage(context),
              const SizedBox(width: 12),

              // Detalles del producto
              Expanded(
                child: _buildProductDetails(context),
              ),

              // Indicador de selección
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.info(context),
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surfaceEmphasis(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child:
            match.product.imageUrl != null && match.product.imageUrl!.isNotEmpty
                ? Image.network(
                    match.product.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderImage(context);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      );
                    },
                  )
                : _buildPlaceholderImage(context),
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Icon(
      Icons.image_outlined,
      color: AppColors.iconMuted(context),
      size: 32,
    );
  }

  Widget _buildProductDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre del producto
        Text(
          match.product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),

        // Indicador de confianza
        ConfidenceIndicator(
          confidence: match.confidence,
          showPercentage: true,
          height: 6,
        ),
        const SizedBox(height: 4),

        // Tipo de match
        Row(
          children: [
            Icon(
              _getMatchTypeIcon(),
              size: 14,
              color: AppColors.textMuted(context),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _formatMatchType(match.matchType),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Información adicional (si existe)
        if (match.product.brandName != null) ...[
          const SizedBox(height: 2),
          Text(
            'Marca: ${match.product.brandName}',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.iconMuted(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  IconData _getMatchTypeIcon() {
    switch (match.matchType.toUpperCase()) {
      case 'EXACT_BARCODE':
        return Icons.qr_code;
      case 'EXACT_HASH':
        return Icons.image;
      case 'BRAND_MODEL':
        return Icons.business;
      case 'CLIP_SIMILARITY':
        return Icons.visibility;
      case 'VECTOR_SIMILARITY':
        return Icons.psychology;
      case 'TAG_CATEGORY':
        return Icons.label;
      default:
        return Icons.help_outline;
    }
  }

  String _formatMatchType(String matchType) {
    switch (matchType.toUpperCase()) {
      case 'EXACT_BARCODE':
        return 'Código de barras';
      case 'EXACT_HASH':
        return 'Imagen exacta';
      case 'BRAND_MODEL':
        return 'Marca y modelo';
      case 'CLIP_SIMILARITY':
        return 'Similitud visual IA';
      case 'VECTOR_SIMILARITY':
        return 'Similitud vectorial';
      case 'TAG_CATEGORY':
        return 'Categoría y tags';
      default:
        return matchType;
    }
  }
}

/// Widget que muestra una lista de productos alternativos
class AlternativeMatchList extends StatelessWidget {
  /// Lista de matches alternativos
  final List<IdentificationMatch> alternatives;

  /// ID del producto seleccionado (si alguno)
  final int? selectedProductId;

  /// Callback cuando se selecciona un producto
  final Function(IdentificationMatch) onMatchSelected;

  const AlternativeMatchList({
    super.key,
    required this.alternatives,
    this.selectedProductId,
    required this.onMatchSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (alternatives.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.list_alt,
                size: 20,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text(
                'Alternativas Sugeridas (${alternatives.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Lista de alternativas
        ...alternatives.map((match) {
          final isSelected = selectedProductId == match.product.id;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: AlternativeMatchCard(
              match: match,
              isSelected: isSelected,
              onTap: () => onMatchSelected(match),
            ),
          );
        }),
      ],
    );
  }
}
