import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../models/invoice_scan/invoice_scan_models.dart';

final Logger _invoiceScanLog = Logger();

/// Servicio para escaneo y OCR de facturas/documentos
///
/// Comunicación con backend para:
/// - Escanear facturas y extraer productos
/// - Buscar productos por nombre en la base de datos
/// - Confirmar y registrar productos extraídos
class InvoiceScanService {
  final Dio _dio;

  InvoiceScanService({
    required Dio dio,
  }) : _dio = dio;

  /// Escanea una factura/documento y extrae los productos
  ///
  /// Flujo:
  /// 1. Convierte imagen a base64
  /// 2. Envía al backend para OCR con GPT-4 Vision
  /// 3. Backend extrae texto, identifica productos y cantidades
  /// 4. Busca productos existentes por nombre (similarity)
  /// 5. Calcula precios de venta con margen
  /// 6. Retorna lista de productos para verificación
  ///
  /// [imageBytes] - Bytes de la imagen de la factura
  /// [imageName] - Nombre del archivo de imagen
  /// [userId] - ID del usuario que escanea
  /// [defaultProfitMargin] - Porcentaje de ganancia por defecto (default: 30%)
  Future<InvoiceScanResult> scanInvoice({
    required Uint8List imageBytes,
    String imageName = 'invoice.jpg',
    int? userId,
    int defaultProfitMargin = 30,
  }) async {
    _invoiceScanLog.d(
      'Escaneando factura: $imageName, margen: $defaultProfitMargin%',
    );

    try {
      // Convertir imagen a base64
      final imageBase64 = base64Encode(imageBytes);

      // Detectar formato de imagen
      final extension = imageName.split('.').last.toLowerCase();
      final imageFormat = _mapImageFormat(extension);

      // Preparar request
      final requestData = InvoiceScanRequest(
        imageBase64: imageBase64,
        imageFormat: imageFormat,
        userId: userId,
        defaultProfitMargin: defaultProfitMargin,
      ).toJson();

      _invoiceScanLog.d(
        'Enviando imagen de ${imageBytes.length} bytes para OCR',
      );

      // Llamar al backend
      final response = await _dio.post(
        '/api/v1/invoice-scan/scan',
        data: requestData,
      );

      // Parsear response
      final apiResponse = response.data;

      if (apiResponse['success'] == true) {
        final resultData = apiResponse['data'];
        final result = InvoiceScanResult.fromJson(resultData);

        _invoiceScanLog.i(
          '✅ Escaneo completado: status=${result.status}, '
          'productos=${result.totalProducts}, '
          'matched=${result.matchedProducts}, '
          'tiempo=${result.processingTimeMs}ms',
        );

        // Log de productos extraídos
        for (final product in result.products) {
          _invoiceScanLog.d(
            '   📦 ${product.extractedName}: qty=${product.quantity}, '
            'precio=${product.unitPrice}, '
            'confianza=${(product.extractionConfidence * 100).toStringAsFixed(1)}%, '
            'match=${product.matchedProduct?.name ?? "NUEVO"}',
          );
        }

        return result;
      } else {
        throw Exception(
            apiResponse['error'] ?? 'Error desconocido en escaneo de factura');
      }
    } on DioException catch (e) {
      _logDioError(e, context: 'Escanear factura');
      rethrow;
    } catch (e) {
      _invoiceScanLog.e('Error inesperado: $e');
      rethrow;
    }
  }

  /// Busca productos por nombre en la base de datos
  ///
  /// Usado para buscar manualmente cuando el OCR no encuentra coincidencia
  ///
  /// [query] - Texto a buscar
  /// [limit] - Máximo de resultados
  Future<List<MatchedProduct>> searchProductsByName({
    required String query,
    int limit = 10,
  }) async {
    _invoiceScanLog.d('Buscando productos: "$query"');

    try {
      final response = await _dio.get(
        '/api/v1/invoice-scan/search-products',
        queryParameters: {
          'query': query,
          'limit': limit,
        },
      );

      final apiResponse = response.data;

      if (apiResponse['success'] == true) {
        final productsData = apiResponse['data'] as List;
        final products =
            productsData.map((json) => MatchedProduct.fromJson(json)).toList();

        _invoiceScanLog.i('✅ ${products.length} productos encontrados');

        return products;
      } else {
        throw Exception(apiResponse['error'] ?? 'Error buscando productos');
      }
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar productos por nombre');
      rethrow;
    }
  }

  /// Confirma los productos extraídos y los registra en el stock
  ///
  /// Flujo:
  /// 1. Recibe lista de productos confirmados por el usuario
  /// 2. Para cada producto:
  ///    - Si tiene productId: crea registro de stock
  ///    - Si createAsNew: crea producto nuevo y luego stock
  /// 3. Retorna resultado del registro
  ///
  /// [products] - Lista de productos confirmados
  /// [warehouseId] - ID del almacén destino
  /// [personId] - ID del proveedor (opcional)
  /// [entryDate] - Fecha de entrada
  /// [userId] - ID del usuario que registra
  Future<void> confirmAndRegister({
    required List<ConfirmedInvoiceProduct> products,
    required int warehouseId,
    int? personId,
    DateTime? entryDate,
    required int userId,
  }) async {
    _invoiceScanLog.d(
      'Confirmando ${products.length} productos para registro',
    );

    try {
      final requestData = InvoiceConfirmationRequest(
        products: products,
        warehouseId: warehouseId,
        personId: personId,
        entryDate: entryDate,
        userId: userId,
      ).toJson();

      final response = await _dio.post(
        '/api/v1/invoice-scan/confirm',
        data: requestData,
      );

      final apiResponse = response.data;

      if (apiResponse['success'] == true) {
        _invoiceScanLog.i(
          '✅ ${products.length} productos registrados exitosamente',
        );
      } else {
        throw Exception(apiResponse['error'] ?? 'Error registrando productos');
      }
    } on DioException catch (e) {
      _logDioError(e, context: 'Confirmar y registrar productos');
      rethrow;
    }
  }

  /// Mapea extensión de archivo a formato de imagen
  String _mapImageFormat(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'webp':
        return 'webp';
      case 'gif':
        return 'gif';
      case 'bmp':
        return 'bmp';
      case 'pdf':
        return 'pdf';
      default:
        return 'jpeg';
    }
  }

  /// Log de errores Dio
  void _logDioError(DioException e, {required String context}) {
    _invoiceScanLog.e('❌ Error en $context: ${e.message}');
    if (e.response != null) {
      _invoiceScanLog.e('Respuesta del servidor: ${e.response?.data}');
    }
  }
}
