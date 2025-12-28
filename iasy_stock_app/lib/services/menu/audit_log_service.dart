import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../models/menu/audit_log_model.dart';

final Logger log = Logger();

class AuditLogService {
  final Dio _dio;

  AuditLogService(this._dio);

  Future<List<AuditLogModel>> getAll({int page = 0, int size = 10}) async {
    log.d('Servicio para obtener todos los logs de auditoría');
    try {
      final response = await _dio.get(
        '/api/audit-logs',
        queryParameters: {'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['logs'];
      return (data as List).map((e) => AuditLogModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener todos los logs');
      rethrow;
    }
  }

  Future<AuditLogModel> getById(int id) async {
    log.d('Servicio para obtener log con ID: $id');
    try {
      final response = await _dio.get('/api/audit-logs/$id');
      return AuditLogModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener log por ID');
      rethrow;
    }
  }

  Future<AuditLogModel> create(AuditLogModel logEntry) async {
    log.d('Servicio para crear log: ${logEntry.toJson()}');
    try {
      final response =
          await _dio.post('/api/audit-logs', data: logEntry.toJson());
      return AuditLogModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Crear log');
      rethrow;
    }
  }

  Future<void> deleteById(int id) async {
    log.d('Servicio para eliminar log con ID: $id');
    try {
      await _dio.delete('/api/audit-logs/$id');
    } on DioException catch (e) {
      _logDioError(e, context: 'Eliminar log por ID');
      rethrow;
    }
  }

  Future<List<AuditLogModel>> findByUserId(int userId,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar logs por userId: $userId');
    try {
      final response = await _dio.get(
        '/api/audit-logs/search/by-user',
        queryParameters: {'userId': userId, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['logs'];
      return (data as List).map((e) => AuditLogModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar logs por usuario');
      rethrow;
    }
  }

  Future<List<AuditLogModel>> findByAction(String action,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar logs por acción: $action');
    try {
      final response = await _dio.get(
        '/api/audit-logs/search/by-action',
        queryParameters: {'action': action, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['logs'];
      return (data as List).map((e) => AuditLogModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar logs por acción');
      rethrow;
    }
  }

  Future<List<AuditLogModel>> findByCreatedAtBetween(
      DateTime start, DateTime end,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar logs entre fechas: $start - $end');
    try {
      final response = await _dio.get(
        '/api/audit-logs/search/by-date-range',
        queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
          'page': page,
          'size': size,
        },
      );
      final data =
          response.data is List ? response.data : response.data['logs'];
      return (data as List).map((e) => AuditLogModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar logs por rango de fechas');
      rethrow;
    }
  }

  Future<void> deleteByUserId(int userId) async {
    log.d('Servicio para eliminar logs por userId: $userId');
    try {
      await _dio.delete(
        '/api/audit-logs/delete/by-user',
        queryParameters: {'userId': userId},
      );
    } on DioException catch (e) {
      _logDioError(e, context: 'Eliminar logs por usuario');
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
