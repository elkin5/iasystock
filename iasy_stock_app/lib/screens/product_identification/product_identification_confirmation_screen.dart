import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/product_identification/product_identification_cubit.dart';
import '../../models/product_identification/product_identification_models.dart';
import '../../widgets/notification_helper.dart';
import '../../widgets/product_identification/alternative_match_card.dart';
import '../../widgets/product_identification/confidence_indicator.dart';

/// Pantalla de confirmación de identificación de producto
///
/// Muestra el resultado de la identificación y permite al usuario:
/// - Confirmar que la identificación es correcta
/// - Seleccionar un producto alternativo
/// - Buscar manualmente si ninguno es correcto
class ProductIdentificationConfirmationScreen extends StatefulWidget {
  /// Resultado de la identificación
  final ProductIdentificationResult result;

  /// Fuente de la identificación (SALE, STOCK, MANUAL)
  final String source;

  /// Si se debe navegar de regreso automáticamente al confirmar
  final bool autoNavigateBack;

  /// Bytes de la imagen capturada (opcional)
  /// Si se proporciona, se muestra en lugar de imageUrl del producto
  final Uint8List? capturedImageBytes;

  const ProductIdentificationConfirmationScreen({
    super.key,
    required this.result,
    required this.source,
    this.autoNavigateBack = true,
    this.capturedImageBytes,
  });

  @override
  State<ProductIdentificationConfirmationScreen> createState() =>
      _ProductIdentificationConfirmationScreenState();
}

class _ProductIdentificationConfirmationScreenState
    extends State<ProductIdentificationConfirmationScreen> {
  /// Producto seleccionado (inicialmente el sugerido)
  late ProductSummary _selectedProduct;

  /// Si el usuario cambió la selección original
  bool _isSelectionModified = false;

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.result.product;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Identificación'),
        elevation: 2,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Contenido scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: Producto Identificado
                    _buildIdentifiedProductHeader(),
                    const SizedBox(height: 16),

                    // Imagen del producto identificado
                    _buildProductImage(),
                    const SizedBox(height: 16),

                    // Detalles del producto identificado
                    _buildProductDetails(),
                    const SizedBox(height: 16),

                    // Métricas de identificación
                    _buildMetrics(),
                    const SizedBox(height: 24),

                    // Mensaje si se requiere validación
                    if (widget.result.requiresValidation)
                      _buildValidationRequiredCard(),

                    if (widget.result.requiresValidation)
                      const SizedBox(height: 24),

                    // Alternativas (si existen)
                    if (widget.result.alternativeMatches.isNotEmpty) ...[
                      _buildAlternativesHeader(),
                      const SizedBox(height: 12),
                      AlternativeMatchList(
                        alternatives: widget.result.alternativeMatches,
                        selectedProductId: _selectedProduct.id,
                        onMatchSelected: _onAlternativeSelected,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),

            // Botones de acción (fijos en la parte inferior)
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// Header que indica claramente el producto identificado
  Widget _buildIdentifiedProductHeader() {
    final confidence = widget.result.confidence;
    final isHighConfidence = confidence >= 0.8;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighConfidence
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighConfidence ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isHighConfidence ? Icons.check_circle : Icons.help_outline,
            color: isHighConfidence ? Colors.green : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHighConfidence
                      ? '✅ Producto Identificado'
                      : '⚠️ Identificación con Baja Confianza',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isHighConfidence
                        ? Colors.green[900]
                        : Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isHighConfidence
                      ? 'Verifica que sea correcto y confirma'
                      : 'Revisa las alternativas o busca manualmente',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
        border: Border.all(
          color: _isSelectionModified ? Colors.blue : Colors.green,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _buildImageWidget(),
      ),
    );
  }

  /// Construye el widget de imagen apropiado
  /// Prioridad: imagen capturada > URL del producto > placeholder
  Widget _buildImageWidget() {
    // 1. Si hay imagen capturada, mostrarla
    if (widget.capturedImageBytes != null) {
      return Image.memory(
        widget.capturedImageBytes!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    }

    // 2. Si no hay imagen capturada, intentar mostrar imageUrl del producto
    if (_selectedProduct.imageUrl != null &&
        _selectedProduct.imageUrl!.isNotEmpty) {
      return Image.network(
        _selectedProduct.imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }

    // 3. Si no hay ninguna imagen, mostrar placeholder
    return _buildPlaceholderImage();
  }

  /// Header para la sección de alternativas
  Widget _buildAlternativesHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿No es el producto correcto?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Selecciona una de estas alternativas similares',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildPlaceholderImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Imagen no disponible',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del producto
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedProduct.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isSelectionModified)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                    child: const Text(
                      'Modificado',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            // Descripción
            if (_selectedProduct.description != null &&
                _selectedProduct.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _selectedProduct.description!,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                ),
              ),
            ],

            // Información adicional
            const SizedBox(height: 12),
            _buildInfoRow(Icons.business, 'Marca',
                _selectedProduct.brandName ?? 'No especificada'),

            if (_selectedProduct.modelNumber != null)
              _buildInfoRow(Icons.tag, 'Modelo', _selectedProduct.modelNumber!),

            if (_selectedProduct.barcodeData != null)
              _buildInfoRow(Icons.qr_code, 'Código de barras',
                  _selectedProduct.barcodeData!),

            if (_selectedProduct.inferredCategory != null)
              _buildInfoRow(Icons.category, 'Categoría',
                  _selectedProduct.inferredCategory!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nivel de confianza detallado
        ConfidenceIndicatorDetailed(
          confidence: widget.result.confidence,
        ),
        const SizedBox(height: 12),

        // Información adicional de métricas
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                if (widget.result.matchType != null)
                  _buildMetricRow(
                    Icons.search,
                    'Método de identificación',
                    _formatMatchType(widget.result.matchType!),
                  ),
                _buildMetricRow(
                  Icons.access_time,
                  'Tiempo de procesamiento',
                  '${(widget.result.processingTimeMs / 1000).toStringAsFixed(1)}s',
                ),
                if (widget.result.similarity != null)
                  _buildMetricRow(
                    Icons.analytics,
                    'Similitud',
                    '${(widget.result.similarity! * 100).toStringAsFixed(1)}%',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationRequiredCard() {
    return Card(
      elevation: 2,
      color: Colors.orange.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.orange.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Requiere validación',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Por favor verifica que la identificación sea correcta',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Botón principal de confirmación
          ElevatedButton.icon(
            onPressed: () =>
                _confirmIdentification(wasCorrect: !_isSelectionModified),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.check_circle),
            label: Text(
              _isSelectionModified
                  ? 'Confirmar Producto Seleccionado'
                  : 'Confirmar - Identificación Correcta',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),

          // Botón de búsqueda manual
          OutlinedButton.icon(
            onPressed: _searchManually,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.search),
            label: const Text('Ninguno es correcto - Buscar manualmente'),
          ),
        ],
      ),
    );
  }

  void _onAlternativeSelected(IdentificationMatch match) {
    setState(() {
      _selectedProduct = match.product;
      _isSelectionModified = _selectedProduct.id != widget.result.product.id;
    });
  }

  Future<void> _confirmIdentification({required bool wasCorrect}) async {
    // Obtener userId del auth state
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthStateAuthenticated) {
      NotificationHelper.showError(
        context,
        'Error: Usuario no autenticado',
      );
      return;
    }

    // Parsear userId de String a int
    final userId = int.tryParse(authState.user.id);
    if (userId == null) {
      NotificationHelper.showError(
        context,
        'Error: ID de usuario inválido',
      );
      return;
    }

    // Trigger validación (feedback loop ML)
    try {
      await context.read<ProductIdentificationCubit>().validateIdentification(
            imageHash: widget.result.metadata['imageHash'] as String? ?? '',
            suggestedProductId: widget.result.product.id,
            actualProductId: _selectedProduct.id,
            confidenceScore: widget.result.confidence,
            matchType: widget.result.matchType ?? 'UNKNOWN',
            wasCorrect: wasCorrect,
            userId: userId,
            source: widget.source,
          );

      // Mostrar mensaje de éxito
      if (mounted) {
        NotificationHelper.showSuccess(
          context,
          'Validación guardada correctamente',
        );

        // Retornar producto confirmado
        if (widget.autoNavigateBack) {
          Navigator.pop(context, _selectedProduct);
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(
          context,
          'Error al guardar validación: $e',
        );
      }
    }
  }

  void _searchManually() {
    // TODO: Navegar a búsqueda manual de productos
    // Por ahora, simplemente retornar null
    Navigator.pop(context, null);
  }

  String _formatMatchType(String matchType) {
    switch (matchType.toUpperCase()) {
      case 'EXACT_BARCODE':
        return 'Código de barras exacto';
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
