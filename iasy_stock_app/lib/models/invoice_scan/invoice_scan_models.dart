import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice_scan_models.freezed.dart';
part 'invoice_scan_models.g.dart';

/// Modelo para solicitud de escaneo de factura/documento
@freezed
class InvoiceScanRequest with _$InvoiceScanRequest {
  const factory InvoiceScanRequest({
    required String imageBase64,
    @Default('jpeg') String imageFormat,
    @Default('MOBILE_APP') String source,
    int? userId,

    /// Porcentaje por defecto para calcular precio de venta
    @Default(30) int defaultProfitMargin,
  }) = _InvoiceScanRequest;

  factory InvoiceScanRequest.fromJson(Map<String, dynamic> json) =>
      _$InvoiceScanRequestFromJson(json);
}

/// Modelo para un producto extraído de la factura
@freezed
class InvoiceProductItem with _$InvoiceProductItem {
  const factory InvoiceProductItem({
    /// ID temporal para identificar el item en la UI
    required String tempId,

    /// Nombre extraído del documento
    required String extractedName,

    /// Cantidad extraída del documento
    required int quantity,

    /// Precio unitario de entrada extraído
    required double unitPrice,

    /// Precio de venta calculado (con margen de ganancia)
    required double salePrice,

    /// Porcentaje de ganancia aplicado
    required int profitMargin,

    /// Producto coincidente encontrado en la base de datos (si existe)
    MatchedProduct? matchedProduct,

    /// Confianza de la extracción OCR (0-1)
    required double extractionConfidence,

    /// Confianza del match con producto existente (0-1)
    double? matchConfidence,

    /// Si el producto fue confirmado por el usuario
    @Default(false) bool isConfirmed,

    /// Si el producto debe ser creado como nuevo
    @Default(false) bool createAsNew,

    /// Notas o advertencias sobre la extracción
    String? notes,
  }) = _InvoiceProductItem;

  factory InvoiceProductItem.fromJson(Map<String, dynamic> json) =>
      _$InvoiceProductItemFromJson(json);
}

/// Modelo resumido de producto coincidente
@freezed
class MatchedProduct with _$MatchedProduct {
  const factory MatchedProduct({
    required int id,
    required String name,
    String? description,
    String? imageUrl,
    int? categoryId,
    int? stockQuantity,
    DateTime? createdAt,
  }) = _MatchedProduct;

  factory MatchedProduct.fromJson(Map<String, dynamic> json) =>
      _$MatchedProductFromJson(json);
}

/// Modelo para resultado del escaneo de factura
@freezed
class InvoiceScanResult with _$InvoiceScanResult {
  const factory InvoiceScanResult({
    required String status,

    /// Fecha extraída de la factura (si existe)
    DateTime? invoiceDate,

    /// Número de factura (si existe)
    String? invoiceNumber,

    /// Proveedor identificado en la factura (si existe)
    String? supplierName,

    /// Lista de productos extraídos
    required List<InvoiceProductItem> products,

    /// Total de productos extraídos
    required int totalProducts,

    /// Productos con match en base de datos
    required int matchedProducts,

    /// Productos sin match (nuevos)
    required int unmatchedProducts,

    /// Total calculado de la factura
    required double totalAmount,

    /// Si requiere validación manual
    required bool requiresValidation,

    /// Tiempo de procesamiento en ms
    required int processingTimeMs,

    /// Texto crudo extraído del OCR
    String? rawText,

    /// Metadatos adicionales
    @Default({}) Map<String, dynamic> metadata,
  }) = _InvoiceScanResult;

  factory InvoiceScanResult.fromJson(Map<String, dynamic> json) =>
      _$InvoiceScanResultFromJson(json);
}

/// Modelo para confirmar productos de la factura y registrarlos
@freezed
class InvoiceConfirmationRequest with _$InvoiceConfirmationRequest {
  const factory InvoiceConfirmationRequest({
    /// Lista de productos confirmados para registrar
    required List<ConfirmedInvoiceProduct> products,

    /// ID del almacén destino
    required int warehouseId,

    /// ID del proveedor (persona)
    int? personId,

    /// Fecha de entrada (por defecto fecha de factura o hoy)
    DateTime? entryDate,

    /// ID del usuario que registra
    required int userId,
  }) = _InvoiceConfirmationRequest;

  factory InvoiceConfirmationRequest.fromJson(Map<String, dynamic> json) =>
      _$InvoiceConfirmationRequestFromJson(json);
}

/// Modelo para producto confirmado de factura
@freezed
class ConfirmedInvoiceProduct with _$ConfirmedInvoiceProduct {
  const factory ConfirmedInvoiceProduct({
    /// ID del producto existente o null si es nuevo
    int? productId,

    /// Nombre del producto (usado si es nuevo)
    required String productName,

    /// Cantidad a registrar
    required int quantity,

    /// Precio de entrada
    required double entryPrice,

    /// Precio de venta
    required double salePrice,

    /// Si se debe crear como nuevo producto
    @Default(false) bool createAsNew,

    /// Categoría para nuevo producto
    int? categoryId,
  }) = _ConfirmedInvoiceProduct;

  factory ConfirmedInvoiceProduct.fromJson(Map<String, dynamic> json) =>
      _$ConfirmedInvoiceProductFromJson(json);
}

/// Estados del escaneo de factura
enum InvoiceScanStatus {
  @JsonValue('SUCCESS')
  success,
  @JsonValue('PARTIAL_SUCCESS')
  partialSuccess,
  @JsonValue('NO_PRODUCTS_FOUND')
  noProductsFound,
  @JsonValue('OCR_FAILED')
  ocrFailed,
  @JsonValue('ERROR')
  error,
}
