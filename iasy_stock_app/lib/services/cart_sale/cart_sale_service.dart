import 'package:dio/dio.dart';
import 'package:iasy_stock_app/models/cart_sale/cart_sale_model.dart';
import 'package:logger/logger.dart';

import '../../models/menu/person_model.dart';
import '../../models/menu/product_model.dart';
import '../../models/menu/stock_model.dart';
import '../menu/person_service.dart';
import '../menu/product_service.dart';

final Logger log = Logger();

class CartSaleService {
  final ProductService _productService;
  final PersonService _personService;
  final Dio _dio;

  CartSaleService({
    required ProductService productService,
    required PersonService personService,
    required Dio dio,
  })  : _productService = productService,
        _personService = personService,
        _dio = dio;

  /// Obtiene productos con filtros específicos para el carrito de compras
  /// Incluye búsqueda por nombre y ordenamiento por más vendidos
  Future<List<ProductModel>> getProductsForCart({
    String? searchQuery,
    int page = 0,
    int size = 20,
    bool orderByMostSold = true,
  }) async {
    log.d('Obteniendo productos para carrito de compras');
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };

      String endpoint = '/api/products';

      if (searchQuery != null && searchQuery.isNotEmpty) {
        endpoint = '/api/products/search/by-name';
        queryParams['name'] = searchQuery;
      }

      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
      );

      final data = response.data is List
          ? response.data
          : response.data['products'] ?? response.data['content'];

      // Filtrar productos que tienen stock mayor a cero
      final products = (data as List)
          .map((e) => ProductModel.fromJson(e))
          .where((product) => (product.stockQuantity ?? 0) > 0)
          .toList();

      return products;
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener productos para carrito');
      rethrow;
    }
  }

  /// Obtiene clientes con filtros específicos para el carrito de compras
  /// Incluye búsqueda por nombre y tipo de cliente
  Future<List<PersonModel>> getClientsForCart({
    String? searchQuery,
    int page = 0,
    int size = 20,
  }) async {
    log.d('Obteniendo clientes para carrito de compras');
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        'type': 'Customer', // Solo clientes, no proveedores
      };

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['keyword'] = searchQuery;
      }

      final response = await _dio.get(
        '/api/persons/search/by-type',
        queryParameters: queryParams,
      );

      final data = response.data is List
          ? response.data
          : response.data['persons'] ?? response.data['content'];

      return (data as List).map((e) => PersonModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener clientes para carrito');
      rethrow;
    }
  }

  /// Crea un nuevo cliente desde el modal del carrito
  Future<PersonModel> createClientFromCart({
    required String name,
    String? email,
    String? phone,
    String? address,
  }) async {
    log.d('Creando nuevo cliente desde carrito: $name');
    try {
      final clientData = {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'type': 'CLIENT',
        'active': true,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final response = await _dio.post('/api/persons', data: clientData);
      return PersonModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Crear cliente desde carrito');
      rethrow;
    }
  }

  /// Obtiene productos más vendidos para mostrar primero en la lista
  /// NOTA: Actualmente obtiene los primeros productos del catálogo con stock > 0.
  /// Si no hay productos con stock, la lista estará vacía (comportamiento correcto).
  /// TODO: Implementar endpoint específico que ordene por cantidad de ventas reales
  Future<List<ProductModel>> getMostSoldProducts({
    int limit = 10,
  }) async {
    log.d('Obteniendo productos más vendidos');
    try {
      // Como no hay endpoint específico para productos más vendidos,
      // obtenemos los primeros productos del catálogo
      final response = await _dio.get(
        '/api/products',
        queryParameters: {
          'page': 0,
          'size': limit,
        },
      );

      final data =
          response.data is List ? response.data : response.data['products'];

      // Filtrar productos que tienen stock mayor a cero
      final products = (data as List)
          .map((e) => ProductModel.fromJson(e))
          .where((product) => (product.stockQuantity ?? 0) > 0)
          .toList();

      return products;
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener productos más vendidos');
      rethrow;
    }
  }

  /// Obtiene información de stock actualizada para un producto
  Future<int> getProductStock(String productId) async {
    log.d('Obteniendo stock del producto: $productId');
    try {
      final response = await _dio.get('/api/products/$productId/stock');
      return response.data['stockQuantity'] ?? 0;
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener stock del producto');
      rethrow;
    }
  }

  /// Busca productos por código de barras o SKU
  Future<ProductModel?> searchProductByCode(String code) async {
    log.d('Buscando producto por código: $code');
    try {
      final response = await _dio.get(
        '/api/products/search/by-barcode',
        queryParameters: {'barcodeData': code},
      );

      if (response.data != null) {
        final product = ProductModel.fromJson(response.data);
        // Solo devolver el producto si tiene stock mayor a cero
        if ((product.stockQuantity ?? 0) > 0) {
          return product;
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Producto no encontrado
      }
      _logDioError(e, context: 'Buscar producto por código');
      rethrow;
    }
  }

  /// Obtiene cliente dummy para ventas rápidas
  /// Como no existe endpoint específico, crea un cliente temporal local
  Future<PersonModel> getDummyClient() async {
    log.d('Creando cliente dummy local');
    try {
      // Crear un cliente dummy local para ventas rápidas
      return PersonModel(
        id: 0,
        // ID temporal
        name: 'Cliente General',
        identification: null,
        identificationType: null,
        cellPhone: null,
        email: null,
        address: null,
        createdAt: DateTime.now(),
        type: 'CLIENT',
      );
    } catch (e) {
      log.e('Error creando cliente dummy: $e');
      rethrow;
    }
  }

  /// Obtiene stocks de un producto específico para calcular precio de venta
  Future<List<StockModel>> getStocksByProductId(int productId) async {
    log.d('Obteniendo stocks del producto: $productId');
    try {
      final response =
          await _dio.get('/api/stocks/search/by-product', queryParameters: {
        'productId': productId,
        'page': 0,
        'size': 100, // Obtener todos los stocks del producto
      });

      final data = response.data is List
          ? response.data
          : response.data['stocks'] ?? response.data['content'];

      return (data as List).map((e) => StockModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener stocks del producto');
      rethrow;
    }
  }

  /// Valida si un producto tiene stock suficiente
  Future<bool> validateProductStock(
      String productId, int requestedQuantity) async {
    try {
      final stock = await getProductStock(productId);
      return stock >= requestedQuantity;
    } catch (e) {
      log.e('Error validando stock del producto: $e');
      return false;
    }
  }

  // Procesa un carrito de compras completo
  // Crea la venta y todos sus items en el backend
  Future<CartSaleModel> processCart({
    required CartSaleModel cartData,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/cart_sale/process',
        data: cartData.toJson(),
      );

      log.d('Carrito procesado exitosamente');
      return CartSaleModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Crear carrito compras');
      rethrow;
    }
  }

  Future<List<CartSaleModel>> getAll({int page = 0, int size = 10}) async {
    log.d('Servicio para obtener todas las ventas con items');
    try {
      final response = await _dio.get(
        '/api/v1/cart_sale',
        queryParameters: {'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['cart_sales'];
      return (data as List).map((e) => CartSaleModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener ventas con items');
      rethrow;
    }
  }

  void _logDioError(DioException e, {required String context}) {
    log.e('Error en $context: ${e.message}');
    if (e.response != null) {
      log.e('Respuesta del servidor: ${e.response?.data}');
    }
  }
}
