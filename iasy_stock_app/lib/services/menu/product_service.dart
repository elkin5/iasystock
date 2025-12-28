import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../config/auth_config.dart';
import '../../models/menu/product_model.dart';

final Logger log = Logger();

class ProductService {
  final Dio _dio;

  ProductService(this._dio);

  Future<List<ProductModel>> getAll({int page = 0, int size = 10}) async {
    log.d('Servicio para obtener todos los productos');
    try {
      final response = await _dio.get(
        '/api/products',
        queryParameters: {'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['products'];
      return (data as List).map((e) => ProductModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener productos');
      rethrow;
    }
  }

  Future<ProductModel> getById(int id) async {
    log.d('Servicio para obtener producto con ID: $id');
    try {
      final response = await _dio.get('/api/products/$id');
      return ProductModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener producto por ID');
      rethrow;
    }
  }

  /// Crea un producto con reconocimiento de imagen usando form-data
  Future<ProductModel> createWithRecognition({
    required String name,
    String? description,
    Uint8List? imageBytes,
    required int categoryId,
    int? stockMinimum,
    DateTime? expirationDate,
  }) async {
    log.d('Servicio para crear producto con reconocimiento: $name');

    try {
      // Crear FormData
      final formData = FormData();

      // Agregar campos requeridos
      formData.fields.add(MapEntry('name', name));
      formData.fields.add(MapEntry('categoryId', categoryId.toString()));

      // Agregar campos opcionales
      if (description != null && description.isNotEmpty) {
        formData.fields.add(MapEntry('description', description));
      }

      if (stockMinimum != null) {
        formData.fields.add(MapEntry('stockMinimum', stockMinimum.toString()));
      }

      if (expirationDate != null) {
        // Formato LocalDate para el backend (yyyy-MM-dd)
        final dateString =
            "${expirationDate.year.toString().padLeft(4, '0')}-${expirationDate.month.toString().padLeft(2, '0')}-${expirationDate.day.toString().padLeft(2, '0')}";
        formData.fields.add(MapEntry('expirationDate', dateString));
      }

      // Agregar imagen si existe
      if (imageBytes != null && imageBytes.isNotEmpty) {
        formData.files.add(MapEntry(
          'image',
          MultipartFile.fromBytes(
            imageBytes,
            filename: 'product_image.jpg',
            contentType: DioMediaType('image', 'jpeg'),
          ),
        ));
      }

      final response = await _dio.post(
        '/api/products/with-recognition',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return ProductModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Crear producto con reconocimiento');
      rethrow;
    }
  }

  Future<ProductModel> update(int id, ProductModel product) async {
    log.d(
        'Servicio para actualizar producto con ID: $id, datos: ${product.toJson()}');
    try {
      final response =
          await _dio.put('/api/products/$id', data: product.toJson());
      return ProductModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Actualizar producto');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    log.d('Servicio para eliminar producto con ID: $id');
    try {
      await _dio.delete('/api/products/$id');
    } on DioException catch (e) {
      _logDioError(e, context: 'Eliminar producto');
      rethrow;
    }
  }

  /// Renueva la URL de imagen de un producto cuando expira
  /// Útil para manejar URLs firmadas temporales del backend seguro
  Future<String> refreshImageUrl(int productId) async {
    log.d('Renovando URL de imagen para producto: $productId');

    try {
      final response = await _dio.post(
        '/api/products/$productId/refresh-image-url',
      );

      final data = response.data as Map<String, dynamic>;
      var newImageUrl = data['imageUrl'] as String;

      // Si la URL apunta a localhost, reemplazar por host accesible desde el cliente
      newImageUrl = _normalizeMinioHost(newImageUrl);

      log.i('URL de imagen renovada exitosamente para producto $productId');
      return newImageUrl;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data as Map<String, dynamic>?;
        final errorMessage =
            errorData?['error'] as String? ?? 'Producto no tiene imagen';
        log.w('No se pudo renovar URL: $errorMessage');
        throw Exception('No se pudo renovar la URL de imagen: $errorMessage');
      } else {
        _logDioError(e, context: 'Renovar URL de imagen');
        rethrow;
      }
    }
  }

  Future<List<ProductModel>> findByName(String name,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar productos por nombre: $name');
    try {
      final response = await _dio.get(
        '/api/products/search/by-name',
        queryParameters: {'name': name, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['products'];
      return (data as List).map((e) => ProductModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar productos por nombre');
      rethrow;
    }
  }

  Future<List<ProductModel>> findByCategoryId(int categoryId,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar productos por categoría: $categoryId');
    try {
      final response = await _dio.get(
        '/api/products/search/by-category',
        queryParameters: {'categoryId': categoryId, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['products'];
      return (data as List).map((e) => ProductModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar productos por categoría');
      rethrow;
    }
  }

  Future<List<ProductModel>> findByStockQuantityGreaterThan(int quantity,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar productos con stock mayor a: $quantity');
    try {
      final response = await _dio.get(
        '/api/products/search/by-stock-gt',
        queryParameters: {'quantity': quantity, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['products'];
      return (data as List).map((e) => ProductModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar productos por cantidad en stock');
      rethrow;
    }
  }

  Future<List<ProductModel>> findByExpirationDateBefore(DateTime expirationDate,
      {int page = 0, int size = 10}) async {
    log.d(
        'Servicio para buscar productos con expiración antes de: $expirationDate');
    try {
      final response = await _dio.get(
        '/api/products/search/by-expiration-date',
        queryParameters: {
          'expirationDate': expirationDate.toIso8601String().split('T').first,
          'page': page,
          'size': size,
        },
      );
      final data =
          response.data is List ? response.data : response.data['products'];
      return (data as List).map((e) => ProductModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar productos por fecha de expiración');
      rethrow;
    }
  }

  void _logDioError(DioException e, {String? context}) {
    final responseData = e.response?.data;
    if (context != null) {
      log.e('[$context] Error: $responseData');
    } else {
      log.e('Error: $responseData');
    }
  }

  String _normalizeMinioHost(String signedUrl) {
    final uri = Uri.tryParse(signedUrl);
    if (uri == null || uri.host.isEmpty) {
      return signedUrl;
    }

    final lowerHost = uri.host.toLowerCase();
    // Incluir 10.0.2.2 que es el alias de localhost desde el emulador Android
    final isLoopbackHost = lowerHost == 'localhost' ||
        lowerHost == '127.0.0.1' ||
        lowerHost == '::1' ||
        lowerHost == '10.0.2.2';
    final useDevOverride = AuthConfig.devHostOverride.isNotEmpty;

    if (!isLoopbackHost && !useDevOverride) {
      return signedUrl;
    }

    final resolvedHost = useDevOverride
        ? AuthConfig.devHostOverride
        : (AuthConfig.isDevelopment ? AuthConfig.defaultLocalHost : uri.host);

    int resolvedPort;
    if (uri.hasPort) {
      resolvedPort = uri.port;
    } else if (useDevOverride || isLoopbackHost) {
      resolvedPort = AuthConfig.minioPort;
    } else if (uri.scheme == 'https') {
      resolvedPort = 443;
    } else {
      resolvedPort = 80;
    }

    final normalizedUri = uri.replace(host: resolvedHost, port: resolvedPort);
    log.d(
        'MinIO URL normalizada de ${uri.toString()} a ${normalizedUri.toString()}');
    return normalizedUri.toString();
  }
}
