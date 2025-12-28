import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../models/menu/promotion_model.dart';

final Logger log = Logger();

class PromotionService {
  final Dio _dio;

  PromotionService(this._dio);

  Future<List<PromotionModel>> getAll({int page = 0, int size = 10}) async {
    log.d('Servicio para obtener todas las promociones');
    try {
      final response = await _dio.get(
        '/api/promotions',
        queryParameters: {'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['promotions'];
      return (data as List).map((e) => PromotionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener promociones');
      rethrow;
    }
  }

  Future<PromotionModel> getById(int id) async {
    log.d('Servicio para obtener promoción con ID: $id');
    try {
      final response = await _dio.get('/api/promotions/$id');
      return PromotionModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener promoción por ID');
      rethrow;
    }
  }

  Future<PromotionModel> create(PromotionModel promotion) async {
    log.d('Servicio para crear promoción: ${promotion.toJson()}');
    try {
      final response =
          await _dio.post('/api/promotions', data: promotion.toJson());
      return PromotionModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Crear promoción');
      rethrow;
    }
  }

  Future<PromotionModel> update(int id, PromotionModel promotion) async {
    log.d(
        'Servicio para actualizar promoción con ID: $id, datos: ${promotion.toJson()}');
    try {
      final response =
          await _dio.put('/api/promotions/$id', data: promotion.toJson());
      return PromotionModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Actualizar promoción');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    log.d('Servicio para eliminar promoción con ID: $id');
    try {
      await _dio.delete('/api/promotions/$id');
    } on DioException catch (e) {
      _logDioError(e, context: 'Eliminar promoción');
      rethrow;
    }
  }

  Future<List<PromotionModel>> findByDescription(String description,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar promociones por descripción: $description');
    try {
      final response = await _dio.get(
        '/api/promotions/search/by-description',
        queryParameters: {
          'description': description,
          'page': page,
          'size': size
        },
      );
      final data =
          response.data is List ? response.data : response.data['promotions'];
      return (data as List).map((e) => PromotionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar promociones por descripción');
      rethrow;
    }
  }

  Future<List<PromotionModel>> findByDiscountRateGreaterThan(double rate,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar promociones con descuento mayor a: $rate');
    try {
      final response = await _dio.get(
        '/api/promotions/search/by-discount-gt',
        queryParameters: {'rate': rate, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['promotions'];
      return (data as List).map((e) => PromotionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar promociones por descuento');
      rethrow;
    }
  }

  Future<List<PromotionModel>> findByDateRange(
      DateTime startDate, DateTime endDate,
      {int page = 0, int size = 10}) async {
    log.d(
        'Servicio para buscar promociones activas entre: $startDate y $endDate');
    try {
      final response = await _dio.get(
        '/api/promotions/search/by-date-range',
        queryParameters: {
          'startDate': startDate.toIso8601String().split('T').first,
          'endDate': endDate.toIso8601String().split('T').first,
          'page': page,
          'size': size,
        },
      );
      final data =
          response.data is List ? response.data : response.data['promotions'];
      return (data as List).map((e) => PromotionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar promociones por rango de fechas');
      rethrow;
    }
  }

  Future<List<PromotionModel>> findByProductId(int productId,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar promociones por producto ID: $productId');
    try {
      final response = await _dio.get(
        '/api/promotions/search/by-product',
        queryParameters: {'productId': productId, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['promotions'];
      return (data as List).map((e) => PromotionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar promociones por producto');
      rethrow;
    }
  }

  Future<List<PromotionModel>> findByCategoryId(int categoryId,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar promociones por categoría ID: $categoryId');
    try {
      final response = await _dio.get(
        '/api/promotions/search/by-category',
        queryParameters: {'categoryId': categoryId, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['promotions'];
      return (data as List).map((e) => PromotionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar promociones por categoría');
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
