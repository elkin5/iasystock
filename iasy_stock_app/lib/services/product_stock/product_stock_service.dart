import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../models/menu/person_model.dart';
import '../../models/menu/product_model.dart';
import '../../models/menu/stock_model.dart';
import '../../models/product_stock/product_stock_model.dart';
import '../menu/person_service.dart';
import '../menu/product_service.dart';

final Logger productStockLog = Logger();

class ProductStockService {
  final ProductService _productService;
  final PersonService _personService;
  final Dio _dio;

  ProductStockService({
    required ProductService productService,
    required PersonService personService,
    required Dio dio,
  })  : _productService = productService,
        _personService = personService,
        _dio = dio;

  Future<List<ProductModel>> getProducts({
    String? searchQuery,
    int page = 0,
    int size = 20,
  }) async {
    productStockLog.d('Consultando productos para gestión de stock');
    try {
      if (searchQuery != null && searchQuery.isNotEmpty) {
        return _productService.findByName(
          searchQuery,
          page: page,
          size: size,
        );
      }

      return _productService.getAll(page: page, size: size);
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener productos para stock');
      rethrow;
    }
  }

  Future<List<PersonModel>> getProviders({
    String? searchQuery,
    int page = 0,
    int size = 20,
  }) async {
    productStockLog.d('Consultando proveedores para gestión de stock');
    try {
      final List<PersonModel> providers;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        providers = await _personService.findByNameContaining(
          searchQuery,
          page: page,
          size: size,
        );
      } else {
        providers = await _personService.findByType(
          'Supplier',
          page: page,
          size: size,
        );
      }

      return providers
          .where((provider) =>
              (provider.type ?? '').toUpperCase() == 'SUPPLIER' ||
              (provider.type ?? '').toUpperCase() == 'PROVIDER')
          .toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener proveedores');
      rethrow;
    }
  }

  Future<PersonModel> createProvider({
    required String name,
    String? email,
    String? phone,
    String? address,
  }) async {
    productStockLog.d('Creando proveedor desde flujo de stock: $name');
    try {
      final providerData = {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'type': 'SUPPLIER',
        'active': true,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final response = await _dio.post('/api/persons', data: providerData);
      return PersonModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Crear proveedor');
      rethrow;
    }
  }

  Future<List<StockModel>> getStockHistoryByProduct(int productId) async {
    productStockLog.d('Obteniendo historial de stock para producto $productId');
    try {
      final response = await _dio.get(
        '/api/stocks/search/by-product',
        queryParameters: {
          'productId': productId,
          'page': 0,
          'size': 100,
        },
      );

      final data = response.data is List
          ? response.data
          : response.data['stocks'] ?? response.data['content'];

      return (data as List).map((json) => StockModel.fromJson(json)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener historial de stock por producto');
      rethrow;
    }
  }

  Future<ProductModel?> searchProductByCode(String code) async {
    productStockLog.d('Buscando producto por código: $code');
    try {
      final response = await _dio.get(
        '/api/products/search/by-barcode',
        queryParameters: {'barcodeData': code},
      );

      if (response.data != null) {
        return ProductModel.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      _logDioError(e, context: 'Buscar producto por código');
      rethrow;
    }
  }

  Future<ProductStockModel> processProductStock({
    required ProductStockModel payload,
  }) async {
    productStockLog.d('Procesando registro masivo de stock');
    try {
      final response = await _dio.post(
        '/api/v1/product_stock/process',
        data: payload.toJson(),
      );

      return ProductStockModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Procesar product stock');
      rethrow;
    }
  }

  Future<List<ProductStockModel>> getAll({
    int page = 0,
    int size = 100,
  }) async {
    productStockLog.d('Consultando registros de product stock');
    try {
      final response = await _dio.get(
        '/api/v1/product_stock',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      final data = response.data is List
          ? response.data
          : response.data['product_stock'] ??
              response.data['productStocks'] ??
              response.data['content'];

      return (data as List)
          .map((json) => ProductStockModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener product stock');
      rethrow;
    }
  }

  void _logDioError(DioException e, {required String context}) {
    productStockLog.e('Error en $context: ${e.message}');
    if (e.response != null) {
      productStockLog.e('Respuesta del servidor: ${e.response?.data}');
    }
  }
}
