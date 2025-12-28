import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../models/menu/sale_model.dart';

final Logger log = Logger();

class SaleService {
  final Dio _dio;

  SaleService(this._dio);

  Future<List<SaleModel>> getAll({int page = 0, int size = 10}) async {
    log.d('Servicio para obtener todas las ventas');
    try {
      final response = await _dio.get(
        '/api/sales',
        queryParameters: {'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['sales'];
      return (data as List).map((e) => SaleModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener ventas');
      rethrow;
    }
  }

  Future<SaleModel> getById(int id) async {
    log.d('Servicio para obtener venta con ID: $id');
    try {
      final response = await _dio.get('/api/sales/$id');
      return SaleModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener venta por ID');
      rethrow;
    }
  }

  Future<SaleModel> create(SaleModel sale) async {
    log.d('Servicio para crear venta: ${sale.toJson()}');
    try {
      final response = await _dio.post('/api/sales', data: sale.toJson());
      return SaleModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Crear venta');
      rethrow;
    }
  }

  Future<SaleModel> update(int id, SaleModel sale) async {
    log.d(
        'Servicio para actualizar venta con ID: $id, datos: ${sale.toJson()}');
    try {
      final response = await _dio.put('/api/sales/$id', data: sale.toJson());
      return SaleModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Actualizar venta');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    log.d('Servicio para eliminar venta con ID: $id');
    try {
      await _dio.delete('/api/sales/$id');
    } on DioException catch (e) {
      _logDioError(e, context: 'Eliminar venta');
      rethrow;
    }
  }

  Future<List<SaleModel>> findByUserId(int userId,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar ventas por usuario ID: $userId');
    try {
      final response = await _dio.get(
        '/api/sales/search/by-user',
        queryParameters: {'userId': userId, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['sales'];
      return (data as List).map((e) => SaleModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar ventas por usuario');
      rethrow;
    }
  }

  Future<List<SaleModel>> findByPersonId(int personId,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar ventas por persona ID: $personId');
    try {
      final response = await _dio.get(
        '/api/sales/search/by-person',
        queryParameters: {'personId': personId, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['sales'];
      return (data as List).map((e) => SaleModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar ventas por persona');
      rethrow;
    }
  }

  Future<List<SaleModel>> findBySaleDate(DateTime saleDate,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar ventas por fecha: $saleDate');
    try {
      final response = await _dio.get(
        '/api/sales/search/by-date',
        queryParameters: {
          'saleDate': saleDate.toIso8601String(),
          'page': page,
          'size': size,
        },
      );
      final data =
          response.data is List ? response.data : response.data['sales'];
      return (data as List).map((e) => SaleModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar ventas por fecha');
      rethrow;
    }
  }

  Future<List<SaleModel>> findByTotalAmountGreaterThan(double amount,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar ventas con monto mayor a: $amount');
    try {
      final response = await _dio.get(
        '/api/sales/search/by-amount-gt',
        queryParameters: {'amount': amount, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['sales'];
      return (data as List).map((e) => SaleModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar ventas por monto');
      rethrow;
    }
  }

  Future<List<SaleModel>> findByState(String state,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar ventas por estado: $state');
    try {
      final response = await _dio.get(
        '/api/sales/search/by-state',
        queryParameters: {'state': state, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['sales'];
      return (data as List).map((e) => SaleModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar ventas por estado');
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
}
