import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../models/menu/sale_item_model.dart';

final Logger log = Logger();

class SaleItemService {
  final Dio _dio;

  SaleItemService(this._dio);

  Future<List<SaleItemModel>> getAll({int page = 0, int size = 10}) async {
    log.d('Servicio para obtener todos los items de venta');
    try {
      final response = await _dio.get(
        '/api/sale-items',
        queryParameters: {'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['saleItems'];
      return (data as List).map((e) => SaleItemModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener items de venta');
      rethrow;
    }
  }

  Future<SaleItemModel> getById(int id) async {
    log.d('Servicio para obtener item de venta con ID: $id');
    try {
      final response = await _dio.get('/api/sale-items/$id');
      return SaleItemModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener item de venta por ID');
      rethrow;
    }
  }

  Future<SaleItemModel> create(SaleItemModel item) async {
    log.d('Servicio para crear item de venta: ${item.toJson()}');
    try {
      final response = await _dio.post('/api/sale-items', data: item.toJson());
      return SaleItemModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Crear item de venta');
      rethrow;
    }
  }

  Future<SaleItemModel> update(int id, SaleItemModel item) async {
    log.d(
        'Servicio para actualizar item de venta con ID: $id, datos: ${item.toJson()}');
    try {
      final response =
          await _dio.put('/api/sale-items/$id', data: item.toJson());
      return SaleItemModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Actualizar item de venta');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    log.d('Servicio para eliminar item de venta con ID: $id');
    try {
      await _dio.delete('/api/sale-items/$id');
    } on DioException catch (e) {
      _logDioError(e, context: 'Eliminar item de venta');
      rethrow;
    }
  }

  Future<List<SaleItemModel>> findBySaleId(int saleId,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar items por venta ID: $saleId');
    try {
      final response = await _dio.get(
        '/api/sale-items/search/by-sale',
        queryParameters: {'saleId': saleId, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['saleItems'];
      return (data as List).map((e) => SaleItemModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar items por ID de venta');
      rethrow;
    }
  }

  Future<List<SaleItemModel>> findByProductId(int productId,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar items por producto ID: $productId');
    try {
      final response = await _dio.get(
        '/api/sale-items/search/by-product',
        queryParameters: {'productId': productId, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['saleItems'];
      return (data as List).map((e) => SaleItemModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar items por ID de producto');
      rethrow;
    }
  }

  Future<double> calculateTotalBySaleId(int saleId) async {
    log.d('Servicio para calcular total por venta ID: $saleId');
    try {
      final response =
          await _dio.get('/api/sale-items/calculate-total/$saleId');
      return (response.data['total'] as num).toDouble();
    } on DioException catch (e) {
      _logDioError(e, context: 'Calcular total por ID de venta');
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
