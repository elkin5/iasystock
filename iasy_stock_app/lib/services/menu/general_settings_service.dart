import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../models/menu/general_settings_model.dart';

final Logger log = Logger();

class GeneralSettingsService {
  final Dio _dio;

  GeneralSettingsService(this._dio);

  Future<List<GeneralSettingsModel>> getAll(
      {int page = 0, int size = 10}) async {
    log.d('Servicio para obtener todas las configuraciones generales');
    try {
      final response = await _dio.get(
        '/api/general-settings',
        queryParameters: {'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['settings'];
      return (data as List)
          .map((e) => GeneralSettingsModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener configuraciones');
      rethrow;
    }
  }

  Future<GeneralSettingsModel> getById(int id) async {
    log.d('Servicio para obtener configuración con ID: $id');
    try {
      final response = await _dio.get('/api/general-settings/$id');
      return GeneralSettingsModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener configuración por ID');
      rethrow;
    }
  }

  Future<GeneralSettingsModel> create(GeneralSettingsModel setting) async {
    log.d('Servicio para crear configuración: ${setting.toJson()}');
    try {
      final response =
          await _dio.post('/api/general-settings', data: setting.toJson());
      return GeneralSettingsModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Crear configuración');
      rethrow;
    }
  }

  Future<GeneralSettingsModel> update(
      int id, GeneralSettingsModel setting) async {
    log.d(
        'Servicio para actualizar configuración con ID: $id, datos: ${setting.toJson()}');
    try {
      final response =
          await _dio.put('/api/general-settings/$id', data: setting.toJson());
      return GeneralSettingsModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Actualizar configuración');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    log.d('Servicio para eliminar configuración con ID: $id');
    try {
      await _dio.delete('/api/general-settings/$id');
    } on DioException catch (e) {
      _logDioError(e, context: 'Eliminar configuración');
      rethrow;
    }
  }

  Future<GeneralSettingsModel> findByKey(String key) async {
    log.d('Servicio para buscar configuración por key: $key');
    try {
      final response = await _dio.get(
        '/api/general-settings/search/by-key',
        queryParameters: {'key': key},
      );
      return GeneralSettingsModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar configuración por key');
      rethrow;
    }
  }

  Future<List<GeneralSettingsModel>> findByKeyContaining(String keyword,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar configuraciones que contengan: $keyword');
    try {
      final response = await _dio.get(
        '/api/general-settings/search/by-key-containing',
        queryParameters: {'keyword': keyword, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['settings'];
      return (data as List)
          .map((e) => GeneralSettingsModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar configuraciones por fragmento de key');
      rethrow;
    }
  }

  Future<void> deleteByKey(String key) async {
    log.d('Servicio para eliminar configuración por key: $key');
    try {
      await _dio.delete(
        '/api/general-settings/delete/by-key',
        queryParameters: {'key': key},
      );
    } on DioException catch (e) {
      _logDioError(e, context: 'Eliminar configuración por key');
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
