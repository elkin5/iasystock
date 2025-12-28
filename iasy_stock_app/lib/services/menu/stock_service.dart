import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../models/menu/stock_model.dart';

final Logger log = Logger();

class StockService {
  final Dio _dio;

  StockService(this._dio);

  Future<List<StockModel>> getAll({int page = 0, int size = 10}) async {
    log.d('Servicio para obtener todos los registros de stock');
    try {
      final response = await _dio
          .get('/api/stocks', queryParameters: {'page': page, 'size': size});
      final data =
          response.data is List ? response.data : response.data['stocks'];
      return (data as List).map((e) => StockModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener stocks');
      rethrow;
    }
  }

  Future<StockModel> getById(int id) async {
    log.d('Servicio para obtener stock con ID: $id');
    try {
      final response = await _dio.get('/api/stocks/$id');
      return StockModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener stock por ID');
      rethrow;
    }
  }

  Future<StockModel> create(StockModel stock) async {
    log.d('Servicio para crear stock: ${stock.toJson()}');
    try {
      final response = await _dio.post('/api/stocks', data: stock.toJson());
      return StockModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Crear stock');
      rethrow;
    }
  }

  Future<StockModel> update(int id, StockModel stock) async {
    log.d('Servicio para actualizar stock con ID: $id');
    try {
      final response = await _dio.put('/api/stocks/$id', data: stock.toJson());
      return StockModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Actualizar stock');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    log.d('Servicio para eliminar stock con ID: $id');
    try {
      await _dio.delete('/api/stocks/$id');
    } on DioException catch (e) {
      _logDioError(e, context: 'Eliminar stock');
      rethrow;
    }
  }

  Future<List<StockModel>> findByProductId(int productId,
      {int page = 0, int size = 10}) async {
    log.d('Buscar stock por ID de producto: $productId');
    try {
      final response = await _dio.get('/api/stocks/search/by-product',
          queryParameters: {
            'productId': productId,
            'page': page,
            'size': size
          });
      final data =
          response.data is List ? response.data : response.data['stocks'];
      return (data as List).map((e) => StockModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar stock por producto');
      rethrow;
    }
  }

  Future<List<StockModel>> findByWarehouseId(int warehouseId,
      {int page = 0, int size = 10}) async {
    log.d('Buscar stock por ID de almacén: $warehouseId');
    try {
      final response = await _dio.get('/api/stocks/search/by-warehouse',
          queryParameters: {
            'warehouseId': warehouseId,
            'page': page,
            'size': size
          });
      final data =
          response.data is List ? response.data : response.data['stocks'];
      return (data as List).map((e) => StockModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar stock por almacén');
      rethrow;
    }
  }

  Future<List<StockModel>> findByUserId(int userId,
      {int page = 0, int size = 10}) async {
    log.d('Buscar stock por ID de usuario: $userId');
    try {
      final response = await _dio.get('/api/stocks/search/by-user',
          queryParameters: {'userId': userId, 'page': page, 'size': size});
      final data =
          response.data is List ? response.data : response.data['stocks'];
      return (data as List).map((e) => StockModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar stock por usuario');
      rethrow;
    }
  }

  Future<List<StockModel>> findByEntryDate(String entryDate,
      {int page = 0, int size = 10}) async {
    log.d('Buscar stock por fecha de entrada: $entryDate');
    try {
      final response = await _dio.get('/api/stocks/search/by-entry-date',
          queryParameters: {
            'entryDate': entryDate,
            'page': page,
            'size': size
          });
      final data =
          response.data is List ? response.data : response.data['stocks'];
      return (data as List).map((e) => StockModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar stock por fecha');
      rethrow;
    }
  }

  Future<List<StockModel>> findByPersonId(int personId,
      {int page = 0, int size = 10}) async {
    log.d('Buscar stock por ID de persona: $personId');
    try {
      final response = await _dio.get('/api/stocks/search/by-person',
          queryParameters: {'personId': personId, 'page': page, 'size': size});
      final data =
          response.data is List ? response.data : response.data['stocks'];
      return (data as List).map((e) => StockModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar stock por persona');
      rethrow;
    }
  }

  Future<List<StockModel>> findByQuantityGreaterThan(int quantity,
      {int page = 0, int size = 10}) async {
    log.d('Buscar stock con cantidad mayor a $quantity');
    try {
      final response = await _dio.get('/api/stocks/search/by-quantity',
          queryParameters: {'quantity': quantity, 'page': page, 'size': size});
      final data =
          response.data is List ? response.data : response.data['stocks'];
      return (data as List).map((e) => StockModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar stock por cantidad');
      rethrow;
    }
  }

  void _logDioError(DioException e, {String? context}) {
    final responseData = e.response?.data;
    if (context != null) log.e('[$context] Error: $responseData');
  }
}
